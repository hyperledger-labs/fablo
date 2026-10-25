const { test } = require("node:test");
const assert = require("node:assert/strict");
const { spawn, spawnSync } = require("node:child_process");
const { mkdtempSync, writeFileSync, mkdirSync, rmSync, existsSync, symlinkSync } = require("node:fs");
const { tmpdir } = require("node:os");
const path = require("node:path");
const { createInterface } = require("node:readline");

const devHook = "npm i --prefix ./chaincodes/chaincode-kv-node";

test("MCP discovery, command routing, validation, hooks, locking, and failures", { timeout: 120000 }, async (t) => {
  const directory = mkdtempSync(path.join(tmpdir(), "fablo mcp "));
  const script = path.join(directory, "fake fablo.sh");
  // The fake prints extend-config output with the hooks from the post-generate
  // and post-start files.
  writeFileSync(script, `#!/usr/bin/env bash
if [ "$1" = extend-config ]; then
  printf '{\\n  "hooks": {\\n    "postGenerate": "%s",\\n    "postStart": "%s"\\n  }\\n}\\n' "$(cat post-generate 2>/dev/null)" "$(cat post-start 2>/dev/null)"
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
    "chaincode_dev", "chaincode_install", "chaincode_invoke", "chaincode_query", "chaincode_upgrade",
    "chaincodes_install", "chaincodes_list", "channel_fetch", "channel_getinfo", "channel_help", "channel_list",
    "config_export_topology", "config_extend", "config_init", "config_instructions", "config_schema",
    "config_validate", "fablo_help", "fablo_use", "fablo_version", "namespace_init", "namespace_list",
    "network_down", "network_generate", "network_info", "network_prune", "network_recreate", "network_reset",
    "network_restore", "network_snapshot", "network_start", "network_stop", "network_up",
  ]);
  for (const tool of listed.result.tools) assert.ok(tool.description);
  const call = (name, args = {}) => request("tools/call", { name, arguments: args });
  const content = (response) => response.result.content.map((item) => item.text || "").join("\n");
  const expectOk = async (name, args) => {
    const response = await call(name, args);
    assert.ok(response.result, JSON.stringify(response));
    assert.notEqual(response.result.isError, true, `${name}: ${JSON.stringify(response)}`);
    return content(response);
  };
  const expectError = async (name, args, message) => {
    const response = await call(name, args);
    assert.equal(response.result?.isError, true, `${name} ${JSON.stringify(args)}: ${JSON.stringify(response)}`);
    assert.ok(content(response).includes(message), `${name}: ${content(response)}`);
    return content(response);
  };

  const info = await expectOk("network_info");
  assert.ok(info.includes(`Network directory: ${directory}`), info);
  assert.ok(info.includes("Config: none"), info);
  assert.ok((await expectOk("config_instructions")).includes("name: fablo"));
  assert.ok(JSON.parse(await expectOk("config_schema")).properties.hooks);

  const json = '{"Args":["KVContract:put","name","Willy Wonka"]}';
  const cases = [
    ["config_init", { options: "", overrides: "" }, ["init"]],
    ["config_init", { options: " node  dev rest ", overrides: "global.fabricVersion=2.5.12\norgs[0].peer.instances=3\n" },
      ["init", "node", "dev", "rest", "--set", "global.fabricVersion=2.5.12", "--set", "orgs[0].peer.instances=3"]],
    ["config_init", { options: "fabric-x", overrides: "" }, ["init", "fabric-x"]],
    ["config_validate", { config_path: "" }, ["validate"]],
    ["config_validate", { config_path: "configs/other.yaml" }, ["validate", "configs/other.yaml"]],
    ["config_export_topology", { config_path: "", output_path: "docs/topology.mmd" }, ["export-network-topology", "", "docs/topology.mmd"]],
    ["network_generate", { config_path: "", target_path: "" }, ["generate"]],
    ["network_up", { config_path: "" }, ["up"]],
    ["network_recreate", { config_path: "fablo-config.json" }, ["recreate", "fablo-config.json"]],
    ["network_start", {}, ["start"]],
    ["network_stop", {}, ["stop"]],
    ["network_down", {}, ["down"]],
    ["network_reset", {}, ["reset"]],
    ["network_prune", {}, ["prune"]],
    ["network_snapshot", { path: "backups/backup with spaces" }, ["snapshot", "backups/backup with spaces"]],
    ["network_restore", { path: "backup.fablo.tar.gz" }, ["restore", "backup.fablo.tar.gz"]],
    ["chaincodes_install", {}, ["chaincodes", "install"]],
    ["chaincode_install", { chaincode_name: "kv", version: "1.0" }, ["chaincode", "install", "kv", "1.0"]],
    ["chaincode_upgrade", { chaincode_name: "kv", version: "1.1" }, ["chaincode", "upgrade", "kv", "1.1"]],
    ["chaincode_dev", { chaincode_name: "kv" }, ["chaincode", "dev", "kv"]],
    ["chaincode_invoke", { peers: "peer0.org1.example.com,peer0.org2.example.com", channel_name: "my-channel1", chaincode_name: "kv", command: json, transient: "" },
      ["chaincode", "invoke", "peer0.org1.example.com,peer0.org2.example.com", "my-channel1", "kv", json]],
    ["chaincode_query", { peer: "peer0.org1.example.com", channel_name: "my-channel1", chaincode_name: "kv", command: json, transient: '{"secret":"eA=="}' },
      ["chaincode", "query", "peer0.org1.example.com", "my-channel1", "kv", json, '{"secret":"eA=="}']],
    ["chaincodes_list", { peer: "peer0.org1.example.com", channel_name: "my-channel1" }, ["chaincodes", "list", "peer0.org1.example.com", "my-channel1"]],
    ["channel_help", {}, ["channel", "--help"]],
    ["channel_list", { org: "org1", peer: "peer0" }, ["channel", "list", "org1", "peer0"]],
    ["channel_getinfo", { channel_name: "my-channel1", org: "org1", peer: "peer0" }, ["channel", "getinfo", "my-channel1", "org1", "peer0"]],
    ["channel_fetch", { block: "config", channel_name: "my-channel1", org: "org1", peer: "peer0", file: "" }, ["channel", "fetch", "config", "my-channel1", "org1", "peer0"]],
    ["channel_fetch", { block: "12", channel_name: "my-channel1", org: "org1", peer: "peer0", file: "blocks/12.block" }, ["channel", "fetch", "12", "my-channel1", "org1", "peer0", "blocks/12.block"]],
    ["namespace_list", {}, ["namespace", "list"]],
    ["namespace_init", { name: "" }, ["namespace", "init"]],
    ["namespace_init", { name: "token" }, ["namespace", "init", "token"]],
    ["fablo_help", {}, ["help"]],
    ["fablo_version", { verbose: "true" }, ["version", "--verbose"]],
    ["fablo_version", { verbose: "" }, ["version"]],
    ["fablo_use", { version: "" }, ["use"]],
    ["fablo_use", { version: "2.6.0" }, ["use", "2.6.0"]],
  ];
  mkdirSync(path.join(directory, "backups"));
  for (const [name, args, expected] of cases) {
    const output = await expectOk(name, args);
    assert.ok(output.endsWith(expected.map((arg) => `<${arg}>`).join("\n")), `${name}: ${output}`);
    assert.ok(output.includes("fablo mcp "), "Must execute in the configured network directory");
  }
  assert.ok((await expectOk("config_extend", { config_path: "" })).includes('"postGenerate"'));
  const up = await expectOk("network_up", { config_path: "" });
  assert.ok(up.includes("<validate>"), "network_up validates first");

  const injection = "$(touch injected); echo bad";
  const quoted = await expectOk("network_snapshot", { path: injection });
  assert.ok(quoted.includes(`<${injection}>`));
  assert.equal(existsSync(path.join(directory, "injected")), false);

  for (const options of ["develop", "node;touch injected", "--set"]) {
    await expectError("config_init", { options, overrides: "" }, "Unsupported init option");
  }
  for (const overrides of ["global.tls", "hooks.postStart=touch injected", "a=$(touch injected)", "a='b'"]) {
    await expectError("config_init", { options: "", overrides }, "Invalid override");
  }
  // Snapshots hold identities and keys, so they stay in the network directory.
  symlinkSync(tmpdir(), path.join(directory, "outside"));
  for (const target of ["/tmp/backup", "../backup", "backups/../../backup", "-backup", "outside/backup"]) {
    await expectError("network_snapshot", { path: target }, "path");
    await expectError("network_restore", { path: target }, "path");
  }
  await expectError("network_snapshot", { path: "" }, "non-empty path");
  await expectError("config_validate", { config_path: "/etc/fablo-config.json" }, "relative");
  await expectError("network_generate", { config_path: "", target_path: "../target" }, "'..'");
  await expectError("config_export_topology", { config_path: "", output_path: "a b.mmd" }, "output_path may contain");
  await expectError("channel_fetch", { block: "latest", channel_name: "c", org: "o", peer: "p", file: "" }, "block must be");
  await expectError("channel_fetch", { block: "1", channel_name: "c", org: "o", peer: "p", file: "../x" }, "'..'");
  await expectError("chaincode_upgrade", { chaincode_name: "kv", version: injection }, "Invalid chaincode version");
  await expectError("chaincode_invoke", { peers: "peer0 peer1", channel_name: "c", chaincode_name: "kv", command: json, transient: "" }, "Invalid peers");
  await expectError("chaincode_query", { peer: "a,b", channel_name: "c", chaincode_name: "kv", command: json, transient: "" }, "Invalid peer");
  await expectError("chaincode_query", { peer: "p", channel_name: "c", chaincode_name: "kv", command: "", transient: "" }, "chaincode command");
  await expectError("namespace_init", { name: "a;b" }, "Invalid namespace");
  await expectError("fablo_version", { verbose: "yes" }, "verbose must be");
  await expectError("fablo_use", { version: "latest;rm" }, "Invalid version");
  assert.ok((await call("chaincode_upgrade", { chaincode_name: "kv" })).error);
  assert.ok((await call("network_stop", { unexpected: "value" })).error);

  writeFileSync(path.join(directory, "fablo-config.yaml"), "");
  assert.ok((await expectOk("network_info")).includes("Config: fablo-config.yaml"));
  await expectError("config_init", { options: "node", overrides: "" }, "already has a Fablo config");

  // Hooks run on the host, so a config or a generated network with hooks does
  // not start, except for the hook from `fablo init dev`.
  writeFileSync(path.join(directory, "post-generate"), devHook);
  await expectOk("network_up", { config_path: "" });
  await expectOk("network_generate", { config_path: "", target_path: "" });
  for (const [file, value] of [["post-generate", `${devHook}; touch injected`], ["post-start", "touch injected"]]) {
    writeFileSync(path.join(directory, file), value);
    for (const name of ["network_up", "network_recreate", "network_generate"]) {
      const output = await expectError(name, name === "network_generate" ? { config_path: "", target_path: "" } : { config_path: "" }, "sets hooks");
      assert.ok(!/<(up|recreate|generate)>/.test(output), output);
    }
    rmSync(path.join(directory, file));
  }
  const hooksDir = path.join(directory, "fablo-target", "hooks");
  mkdirSync(hooksDir, { recursive: true });
  const template = (name) => `#!/usr/bin/env bash\n\n# The code from this file is called by Fablo\necho "Executing ${name} hook"\n\n`;
  writeFileSync(path.join(hooksDir, "post-start.sh"), template("post-start"));
  writeFileSync(path.join(hooksDir, "post-generate.sh"), `${template("post-generate")}${devHook}\n`);
  await expectOk("network_start");
  assert.ok((await expectOk("network_info")).includes("fablo-target exists"));
  for (const [file, body] of [["post-start.sh", `${template("post-start")}touch injected\n`],
    ["post-generate.sh", `${template("post-generate")}${devHook}\ntouch injected\n`]]) {
    writeFileSync(path.join(hooksDir, file), body);
    for (const name of ["network_start", "network_up"]) {
      const output = await expectError(name, name === "network_up" ? { config_path: "" } : {}, "fablo-target has hooks");
      assert.ok(!/<(start|up)>/.test(output), output);
    }
    writeFileSync(path.join(hooksDir, file), template(file.replace(".sh", "")));
  }
  assert.equal(existsSync(path.join(directory, "injected")), false);

  assert.equal(existsSync(path.join(directory, ".fablo-mcp.lock")), false);
  mkdirSync(path.join(directory, ".fablo-mcp.lock"));
  await expectError("network_stop", {}, "Another MCP operation");
  await expectOk("network_info");
  rmSync(path.join(directory, ".fablo-mcp.lock"), { recursive: true });
  writeFileSync(path.join(directory, "fail"), "");
  await expectError("network_stop", {}, "simulated Docker failure");
  assert.equal(existsSync(path.join(directory, ".fablo-mcp.lock")), false);
});

test("fablo mcp requires an existing network directory", () => {
  for (const args of [["mcp"], ["mcp", path.join(tmpdir(), "missing-fablo-network")]]) {
    const result = spawnSync("bash", [path.join(__dirname, "..", "fablo.sh"), ...args], { encoding: "utf8" });
    assert.equal(result.status, 1);
    assert.equal(result.stdout, "", "stdout is reserved for the MCP protocol");
    assert.ok(result.stderr.includes("requires an existing network directory"), result.stderr);
  }
});
