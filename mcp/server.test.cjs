const { test } = require("node:test");
const assert = require("node:assert/strict");
const { spawn, spawnSync } = require("node:child_process");
const { mkdtempSync, writeFileSync, mkdirSync, rmSync, existsSync } = require("node:fs");
const { tmpdir } = require("node:os");
const path = require("node:path");
const { createInterface } = require("node:readline");

test("MCP discovery, command routing, validation, locking, and failures", { timeout: 60000 }, async (t) => {
  const directory = mkdtempSync(path.join(tmpdir(), "fablo mcp "));
  const script = path.join(directory, "fake fablo.sh");
  writeFileSync(script, `#!/usr/bin/env bash
printf '<%s>\\n' "$PWD" "$@"
if [ -f fail ]; then echo 'simulated Docker failure' >&2; exit 7; fi
`);
  const skill = path.join(directory, "SKILL.md");
  writeFileSync(skill, "# Fake Fablo skill\n");
  const child = spawn("bash", [path.join(__dirname, "start.sh"), directory], {
    cwd: tmpdir(),
    env: { ...process.env, FABLO_MCP_SCRIPT: script, FABLO_MCP_SKILL: skill },
    stdio: ["pipe", "pipe", "pipe"],
  });
  let stderr = "";
  child.stderr.on("data", (data) => { stderr += data; });
  const pending = new Map();
  let nextId = 0;
  const lines = createInterface({ input: child.stdout });
  lines.on("line", (line) => {
    try {
      const message = JSON.parse(line);
      const handler = pending.get(message.id);
      if (handler) {
        pending.delete(message.id);
        handler.resolve(message);
      }
    } catch (error) {
      for (const handler of pending.values()) handler.reject(error);
    }
  });
  child.on("exit", (code) => {
    for (const handler of pending.values()) handler.reject(new Error(`Server exited ${code}: ${stderr}`));
  });
  t.after(async () => {
    const exited = new Promise((resolve) => child.once("exit", resolve));
    child.stdin.end();
    if (child.exitCode === null) await exited;
    lines.close();
    rmSync(directory, { recursive: true, force: true });
  });
  async function request(method, params) {
    const id = ++nextId;
    const response = new Promise((resolve, reject) => pending.set(id, { resolve, reject }));
    child.stdin.write(`${JSON.stringify({ jsonrpc: "2.0", id, method, params })}\n`);
    return response;
  }
  const initialized = await request("initialize", {
    protocolVersion: "2024-11-05", capabilities: {}, clientInfo: { name: "fablo-test", version: "1.0.0" },
  });
  assert.ok(initialized.result.serverInfo);
  child.stdin.write(`${JSON.stringify({ jsonrpc: "2.0", method: "notifications/initialized" })}\n`);
  const listed = await request("tools/list", {});
  assert.deepEqual(listed.result.tools.map((tool) => tool.name).sort(), [
    "chaincode_install", "network_prune", "network_snapshot", "network_start", "network_stop", "network_up",
  ]);
  for (const tool of listed.result.tools) assert.ok(tool.description);
  const call = (name, args = {}) => request("tools/call", { name, arguments: args });
  const content = (response) => response.result.content.map((item) => item.text || "").join("\n");
  const cases = [
    // Empty instructions start the existing config without calling an agent.
    ["network_up", { instructions: "" }, ["up"]],
    ["network_start", {}, ["start"]],
    ["network_stop", {}, ["stop"]],
    ["network_prune", {}, ["prune"]],
    ["network_snapshot", { target_path: "backup with spaces" }, ["snapshot", "backup with spaces"]],
    ["chaincode_install", { chaincode_name: "kv", version: "1.0" }, ["chaincode", "install", "kv", "1.0"]],
  ];
  for (const [name, args, expected] of cases) {
    const response = await call(name, args);
    assert.ok(response.result, JSON.stringify(response));
    assert.notEqual(response.result.isError, true, JSON.stringify(response));
    assert.ok(content(response).endsWith(expected.map((arg) => `<${arg}>`).join("\n")), content(response));
    assert.ok(content(response).includes("fablo mcp "), "Must execute in the configured network directory");
  }
  const injection = "$(touch injected); echo bad";
  const quoted = await call("network_snapshot", { target_path: injection });
  assert.ok(content(quoted).includes(`<${injection}>`));
  assert.equal(existsSync(path.join(directory, "injected")), false);
  const invalid = await call("chaincode_install", { chaincode_name: "kv", version: injection });
  assert.equal(invalid.result.isError, true);
  assert.ok(content(invalid).includes("Invalid chaincode version"));
  assert.equal((await call("network_snapshot", { target_path: "" })).result.isError, true);
  assert.ok((await call("chaincode_install", { chaincode_name: "kv" })).error);
  assert.ok((await call("network_stop", { unexpected: "value" })).error);
  mkdirSync(path.join(directory, ".fablo-mcp.lock"));
  assert.equal((await call("network_stop")).result.isError, true);
  rmSync(path.join(directory, ".fablo-mcp.lock"), { recursive: true });
  writeFileSync(path.join(directory, "fail"), "");
  const failed = await call("network_stop");
  assert.equal(failed.result.isError, true);
  assert.ok(content(failed).includes("simulated Docker failure"));
  assert.equal(existsSync(path.join(directory, ".fablo-mcp.lock")), false);
});

test("the agent's fablo shim allows only config commands", () => {
  const directory = mkdtempSync(path.join(tmpdir(), "fablo mcp shim "));
  try {
    const script = path.join(directory, "fake fablo.sh");
    writeFileSync(script, "printf '<%s>\\n' \"$@\"\n");
    const shim = (...args) => spawnSync("bash", [path.join(__dirname, "agent-fablo.sh"), ...args], {
      env: { ...process.env, FABLO_MCP_SCRIPT: script }, encoding: "utf8",
    });
    for (const command of ["init", "validate", "extend-config"]) {
      const result = shim(command, "arg with spaces");
      assert.equal(result.status, 0, result.stderr);
      assert.equal(result.stdout, `<${command}>\n<arg with spaces>\n`);
    }
    for (const command of ["up", "prune", "down", "generate", ""]) {
      const result = shim(command);
      assert.equal(result.status, 2);
      assert.equal(result.stdout, "");
    }
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
});
