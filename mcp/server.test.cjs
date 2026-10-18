const { test } = require("node:test");
const assert = require("node:assert/strict");
const { spawn } = require("node:child_process");
const { mkdtempSync, writeFileSync, mkdirSync, rmSync, existsSync } = require("node:fs");
const { tmpdir } = require("node:os");
const path = require("node:path");
const { createInterface } = require("node:readline");

test("MCP discovery, command routing, validation, hooks, locking, and failures", { timeout: 60000 }, async (t) => {
  const directory = mkdtempSync(path.join(tmpdir(), "fablo mcp "));
  const script = path.join(directory, "fake fablo.sh");
  // The fake prints extend-config output with the hooks from a "hooks" file.
  writeFileSync(script, `#!/usr/bin/env bash
if [ "$1" = extend-config ]; then
  printf '{\\n  "hooks": {\\n    "postGenerate": "%s",\\n    "postStart": ""\\n  }\\n}\\n' "$(cat hooks 2>/dev/null)"
  exit
fi
printf '<%s>\\n' "$PWD" "$@"
if [ -f fail ]; then echo 'simulated Docker failure' >&2; exit 7; fi
`);
  const child = spawn("bash", [path.join(__dirname, "start.sh"), directory], {
    cwd: tmpdir(),
    env: { ...process.env, FABLO_MCP_SCRIPT: script },
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
    "chaincode_upgrade", "config_init", "config_validate", "network_info", "network_prune", "network_snapshot",
    "network_start", "network_stop", "network_up",
  ]);
  for (const tool of listed.result.tools) assert.ok(tool.description);
  const call = (name, args = {}) => request("tools/call", { name, arguments: args });
  const content = (response) => response.result.content.map((item) => item.text || "").join("\n");
  const info = content(await call("network_info"));
  assert.ok(info.includes(`Network directory: ${directory}`), info);
  assert.ok(info.includes("Config: none"), info);
  const cases = [
    ["config_init", { options: "" }, ["init"]],
    ["config_init", { options: " node  rest " }, ["init", "node", "rest"]],
    ["config_validate", {}, ["validate"]],
    ["network_up", {}, ["up"]],
    ["network_start", {}, ["start"]],
    ["network_stop", {}, ["stop"]],
    ["network_prune", {}, ["prune"]],
    ["network_snapshot", { target_path: "backup with spaces" }, ["snapshot", "backup with spaces"]],
    ["chaincode_upgrade", { chaincode_name: "kv", version: "1.1" }, ["chaincode", "upgrade", "kv", "1.1"]],
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
  for (const options of ["dev", "node fabric-x", "node;touch injected"]) {
    const rejected = await call("config_init", { options });
    assert.equal(rejected.result.isError, true);
    assert.ok(content(rejected).includes("Unsupported init option"), content(rejected));
  }
  writeFileSync(path.join(directory, "fablo-config.yaml"), "");
  assert.ok(content(await call("network_info")).includes("Config: fablo-config.yaml"));
  const existing = await call("config_init", { options: "node" });
  assert.equal(existing.result.isError, true);
  assert.ok(content(existing).includes("already has a Fablo config"), content(existing));
  // Hooks run on the host, so neither a config nor a generated network with
  // hooks starts.
  writeFileSync(path.join(directory, "hooks"), "touch injected");
  const hooked = await call("network_up");
  assert.equal(hooked.result.isError, true);
  assert.ok(content(hooked).includes("sets hooks"), content(hooked));
  assert.ok(!content(hooked).includes("<up>"), content(hooked));
  rmSync(path.join(directory, "hooks"));
  const hooksDir = path.join(directory, "fablo-target", "hooks");
  mkdirSync(hooksDir, { recursive: true });
  const template = '#!/usr/bin/env bash\n\n# The code from this file is called after Fablo starts\necho "Executing post-start hook"\n\n';
  writeFileSync(path.join(hooksDir, "post-start.sh"), template);
  assert.notEqual((await call("network_start")).result.isError, true);
  assert.ok(content(await call("network_info")).includes("fablo-target exists"));
  writeFileSync(path.join(hooksDir, "post-start.sh"), `${template}touch injected\n`);
  for (const name of ["network_start", "network_up"]) {
    const rendered = await call(name);
    assert.equal(rendered.result.isError, true);
    assert.ok(content(rendered).includes("fablo-target has hooks"), content(rendered));
    assert.ok(!content(rendered).includes(`<${name.slice(8)}>`), content(rendered));
  }
  assert.equal(existsSync(path.join(directory, ".fablo-mcp.lock")), false);
  const invalid = await call("chaincode_upgrade", { chaincode_name: "kv", version: injection });
  assert.equal(invalid.result.isError, true);
  assert.ok(content(invalid).includes("Invalid chaincode version"));
  assert.equal((await call("network_snapshot", { target_path: "" })).result.isError, true);
  assert.ok((await call("chaincode_upgrade", { chaincode_name: "kv" })).error);
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
