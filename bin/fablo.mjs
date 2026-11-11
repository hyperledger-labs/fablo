#!/usr/bin/env node

// Entry point of the npm package. It provides the same commands as fablo.sh,
// but the generator commands (init, validate, generate, ...) call the Fablo
// Node.js sources in dist/ directly, so the Fablo Docker image is not needed.
// Network commands (up, down, chaincode, ...) run the scripts generated in
// fablo-target, as fablo.sh does.
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { execute } from "@oclif/core";

const packageDir = path.join(path.dirname(fileURLToPath(import.meta.url)), "..");
const fabloVersion = JSON.parse(fs.readFileSync(path.join(packageDir, "package.json"), "utf-8")).version;

const [command, ...params] = process.argv.slice(2);
const commandCallRoot = process.cwd();
const fabloTarget = path.join(commandCallRoot, "fablo-target");
const networkScripts = [
  ["fabric-docker.sh", "Docker"],
  ["fabric-k8s.sh", "Kubernetes"],
  ["fabric-x-docker.sh", "Fabric-X"],
];

let tempDir;
const getTempDir = () => {
  if (!tempDir) {
    tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "fablo."));
    process.on("exit", () => fs.rmSync(tempDir, { recursive: true, force: true }));
  }
  return tempDir;
};

const fail = (...lines) => {
  lines.forEach((line) => console.error(line));
  process.exit(1);
};

// Runs an external program with the user's terminal and stops on failure, like `set -e`.
const run = (program, args, options = {}) => {
  const result = spawnSync(program, args, { stdio: "inherit", ...options });
  if (result.error) fail(`Error: cannot run ${program}: ${result.error.message}`);
  if (result.status !== 0) process.exit(result.status ?? 1);
};

const isOnPath = (program) => spawnSync("sh", ["-c", `command -v ${program}`], { stdio: "ignore" }).status === 0;

const runHook = (targetDir, name) => {
  const hook = path.join(targetDir, "hooks", name);
  if (fs.existsSync(hook)) {
    fs.chmodSync(hook, 0o755);
    run(hook, []);
  }
};

const getDefaultFabloConfig = () => {
  const yaml = path.join(commandCallRoot, "fablo-config.yaml");
  const json = path.join(commandCallRoot, "fablo-config.json");
  return !fs.existsSync(json) && fs.existsSync(yaml) ? yaml : json;
};

const resolveFabloConfig = (fabloConfig) => {
  const resolved = path.resolve(fabloConfig || getDefaultFabloConfig());
  if (!fs.existsSync(resolved)) fail(`File ${resolved} does not exist`);
  return resolved;
};

// Runs a Fablo generator command from dist/ in this process.
const runGenerator = async (args, { workspace, fabloConfig } = {}) => {
  if (fabloConfig) {
    process.env.FABLO_CONFIG = fabloConfig;
    process.env.CHAINCODES_BASE_DIR = path.dirname(fabloConfig);
  }
  if (workspace) process.chdir(workspace);
  try {
    await execute({ dir: import.meta.url, args });
  } finally {
    process.chdir(commandCallRoot);
  }
};

const printSplash = () => {
  const now = new Date();
  const isChristmas = (now.getMonth() + 1) * 100 + now.getDate() > 1215;
  const logo = isChristmas
    ? [
        "┌──────       *        ┌─────.    ╷           .────.",
        "│           _/_\\_      │      │   │         ╱        ╲ ",
        "├─────     _/___\\_     ├─────:    │        │          │",
        "│         _/_____\\_    │      │   │         ╲        ╱ ",
        "╵            |_|       └─────'    └──────     '────'    ",
      ]
    : [
        "┌──────      .─.       ┌─────.    ╷           .────.",
        "│           /   \\      │      │   │         ╱        ╲ ",
        "├─────     /     \\     ├─────:    │        │          │",
        "│         /───────\\    │      │   │         ╲        ╱ ",
        "╵        /         \\   └─────'    └──────     '────'    ",
      ];
  logo[4] += `v${fabloVersion}`.padStart(24);
  console.log(`
${logo.join("\n")}
\x1b[90m┌┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┐
│ https://fablo.io | created at SoftwareMill | backed by Hyperledger Foundation│
└┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┘\x1b[0m`);
};

// Keep in sync with printHelp in fablo.sh.
const printHelp = () => {
  printSplash();
  console.log(`Usage:
  fablo init [node] [rest] [dev] [ccaas] [gateway] [--set <path>=<value> ...]
    Creates simple Fablo config in current directory with optional Node.js chaincode, CCaaS, REST API, gateway sample, and/or dev mode. Use --set to override generated fields.

  fablo init fabric-x [--set <path>=<value> ...]
    Creates minimal Fablo config for the experimental Fabric-X provider. Cannot be combined with node, rest, dev, ccaas or gateway.

  fablo generate [/path/to/fablo-config.json|yaml [/path/to/fablo/target]]
    Generates network configuration files in the given directory. Default config file path is '$(pwd)/fablo-config.json' or '$(pwd)/fablo-config.yaml', default (and recommended) directory '$(pwd)/fablo-target'.

  fablo up [/path/to/fablo-config.json|yaml]
    Starts the Hyperledger Fabric network for given Fablo configuration file, creates channels, and installs and deploys chaincodes. A source fablo-config.json|yaml must exist; if generated fablo-target files are missing, it calls 'generate' first.

  fablo <down | start | stop>
    Downs, starts or stops the Hyperledger Fabric network for configuration in the current directory. This is similar to down, start and stop commands for Docker Compose.

  fablo reset
    Downs and ups the network. Network state is lost, but the configuration is kept intact.

  fablo prune
    Downs the network and removes all generated files.

  fablo recreate [/path/to/fablo-config.json|yaml]
    Prunes and ups the network. Default config file path is '$(pwd)/fablo-config.json' or '$(pwd)/fablo-config.yaml'.

  fablo chaincodes install
    Installs all chaincodes on relevant peers. Chaincode directory is specified in Fablo config file.

  fablo chaincode install <chaincode-name> <version>
    Installs chaincode on all relevant peers. Chaincode directory is specified in Fablo config file.

  fablo chaincode upgrade <chaincode-name> <version>
    Upgrades chaincode on all relevant peers. Chaincode directory is specified in Fablo config file.

  fablo chaincode dev <chaincode-name>
    Approves and commits a chaincode definition for peers started in dev mode, using the version from the Fablo config file. Supported only on channels with Fabric v2 capabilities.

  fablo chaincode invoke <peer_domains_comma_separated> <channel_name> <chaincode_name> <command> [transient]
    Invokes chaincode with specified parameters. Transient data is optional.

  fablo chaincodes list <peer_domain> <channel_name>
    Lists chaincodes installed on specified peer and channel.

  fablo chaincode query <peer_domain> <channel_name> <chaincode_name> <command> [transient]
    Queries chaincode on a single peer. Transient data is optional.

  fablo channel --help
    To list available channel query options which can be executed on running network.

  fablo namespace <list | init>
    Lists namespaces on the running network, or creates the configured namespace or only the named one if a name is given. Available only for the experimental Fabric-X provider.

  fablo snapshot <target-snapshot-path>
    Creates a snapshot of the network. The snapshot contains all network state, including transactions and identities. It is saved as '<target-snapshot-path>.fablo.tar.gz', unless the given path already ends with 'tar.gz'.

  fablo restore <source-snapshot-path> [hook-command]
    Restores the network from a snapshot, so that it can be started with the 'start' command. Requires the network to be pruned first. The optional hook command is executed in the restored directory before the containers are created.

  fablo validate [/path/to/fablo-config.json|yaml]
    Validates the Fablo config file against the schema and additional checks. Default config file path is '$(pwd)/fablo-config.json' or '$(pwd)/fablo-config.yaml'.

  fablo extend-config [/path/to/fablo-config.json|yaml]
    Reads the Fablo config file, extends it and prints the result as JSON. Useful for debugging.

  fablo export-network-topology [/path/to/fablo-config.json|yaml [outputFile.mmd]]
    Exports the network topology described by the Fablo config file to a Mermaid diagram. Default output file is 'network-topology.mmd'.

  fablo mcp </path/to/network>
    Starts an MCP server over stdio for the network in the given directory, so AI agents can start and manage it. Requires Jaiph.

  fablo use [version]
    Prints how to switch the Fablo version installed from npm.

  fablo <help | --help>
    Prints the manual.

  fablo version [--verbose | -v]
    Prints current Fablo version, with optional details.`);
};

// Same formatting as docker-entrypoint.sh applies in the Fablo Docker image.
const formatGeneratedFiles = (targetDir) => {
  console.log("Formatting generated files");
  if (isOnPath("shfmt")) {
    run("shfmt", ["-i=2", "-l", "-w", targetDir], { stdio: "ignore" });
  } else {
    console.log("Warning: shfmt not found, generated scripts are left unformatted");
  }

  const subdirs = fs.readdirSync(targetDir, { withFileTypes: true }).filter((entry) => entry.isDirectory());
  for (const subdir of subdirs) {
    const dir = path.join(targetDir, subdir.name);
    for (const file of fs.readdirSync(dir).filter((name) => name.endsWith(".yaml"))) {
      const yaml = path.join(dir, file);
      const content = fs
        .readFileSync(yaml, "utf-8")
        .replace(/[ \t]+$/gm, "") // trailing spaces
        .replace(/\n{3,}/g, "\n\n") // duplicated blank lines
        .trim();
      fs.writeFileSync(yaml, `${content}\n`);
    }
  }
};

const snapshotFabloConfigToTarget = (fabloConfig, targetDir) => {
  fs.mkdirSync(targetDir, { recursive: true });
  fs.copyFileSync(fabloConfig, path.join(targetDir, `fablo-config${path.extname(fabloConfig)}`));
};

const generateNetworkConfig = async (fabloConfigParam, fabloTargetParam) => {
  printSplash();
  const fabloConfig = resolveFabloConfig(fabloConfigParam);
  const targetDir = path.resolve(fabloTargetParam || fabloTarget);

  console.log("Generating network config");
  console.log(`    FABLO_VERSION:      ${fabloVersion}`);
  console.log(`    FABLO_CONFIG:       ${fabloConfig}`);
  console.log(`    FABLO_NETWORK_ROOT: ${targetDir}`);

  fs.mkdirSync(targetDir, { recursive: true });
  await runGenerator(["setup-network", fabloConfig], { workspace: targetDir, fabloConfig });
  formatGeneratedFiles(targetDir);

  runHook(targetDir, "post-generate.sh");
  snapshotFabloConfigToTarget(fabloConfig, targetDir);
};

const verifyConfigMatchesOrFail = (fabloConfigParam) => {
  const currentConfig = path.resolve(fabloConfigParam || getDefaultFabloConfig());
  if (!fs.existsSync(currentConfig)) return;

  const storedConfig = ["json", "yaml", "yml"]
    .map((ext) => path.join(fabloTarget, `fablo-config.${ext}`))
    .find((file) => fs.existsSync(file));

  if (!storedConfig) {
    console.log(
      `No stored config snapshot found in '${fabloTarget}'. Storing current config snapshot for future comparisons.`,
    );
    const ext = path.extname(currentConfig);
    if (![".json", ".yaml", ".yml"].includes(ext)) {
      fail(`Error: Unsupported config file extension '${ext}'. Supported extensions are: .json, .yaml`);
    }
    snapshotFabloConfigToTarget(currentConfig, fabloTarget);
    return;
  }

  if (fs.readFileSync(storedConfig).equals(fs.readFileSync(currentConfig))) return;

  console.log(`Error: Fablo configuration has changed since the network at '${fabloTarget}' was generated.`);
  console.log(`Stored config:  ${storedConfig}`);
  console.log(`Current config: ${currentConfig}`);
  console.log("");
  console.log("--- Diff (stored vs current) ---");
  spawnSync("diff", ["-u", storedConfig, currentConfig], { stdio: "inherit" });
  console.log("--------------------------------");
  console.log("");
  console.log("Please run 'fablo prune' to remove the existing network before applying configuration changes,");
  console.log("or run 'fablo recreate [path/to/fablo-config]' to prune and start with the new configuration.");
  process.exit(1);
};

const executeFabloCommand = (...args) => {
  if (!fs.existsSync(fabloTarget)) {
    fail(
      `Error: This command needs the network to be generated at '${fabloTarget}'! Execute 'generate' or 'up' command.`,
    );
  }

  const found = networkScripts.find(([script]) => fs.existsSync(path.join(fabloTarget, script)));
  if (!found) {
    fail(`Error: Corrupted Fablo target directory (${fabloTarget})`, `Cannot execute command ${args[0]}`);
  }

  const [script, label] = found;
  console.log(`Executing Fablo ${label} command: ${args[0]}`);
  fs.chmodSync(path.join(fabloTarget, script), 0o755);
  // fablo.sh always passes eight positional parameters to the generated scripts
  const scriptArgs = [...args, ...Array(8).fill("")].slice(0, Math.max(8, args.length));
  run(path.join(fabloTarget, script), scriptArgs);

  if (args[0] === "up" || args[0] === "start") runHook(fabloTarget, "post-start.sh");
};

const networkPrune = () => {
  for (const [script] of networkScripts) {
    if (fs.existsSync(path.join(fabloTarget, script))) run(path.join(fabloTarget, script), ["down"]);
  }
  console.log(`Removing ${fabloTarget}`);
  fs.rmSync(fabloTarget, { recursive: true, force: true });
};

const networkUp = async (fabloConfigParam) => {
  if (!fs.existsSync(fabloTarget) || fs.readdirSync(fabloTarget).length === 0) {
    console.log("Network target directory is empty");
    await generateNetworkConfig(fabloConfigParam);
  } else {
    verifyConfigMatchesOrFail(fabloConfigParam);
  }
  executeFabloCommand("up");
};

const getSnapshotPath = (snapshotPath = "snapshot") =>
  path.resolve(snapshotPath.endsWith("tar.gz") ? snapshotPath : `${snapshotPath}.fablo.tar.gz`);

const createSnapshot = (snapshotPath) => {
  const archive = getSnapshotPath(snapshotPath);
  console.log(`Creating network snapshot in '${archive}'`);
  if (fs.existsSync(archive)) fail(`Error: Snapshot file '${archive}' already exists!`);

  const dir = getTempDir();
  executeFabloCommand("snapshot", dir);
  const entries = fs.readdirSync(dir).filter((name) => !name.startsWith("."));
  run("tar", ["czf", archive, "-C", dir, ...entries]);
  console.log(`📦 Created snapshot at '${archive}'!`);
};

const restoreSnapshot = (snapshotPath, hookCommand = "") => {
  const archive = getSnapshotPath(snapshotPath);
  console.log(`📦 Restoring network from '${archive}'`);
  if (!fs.existsSync(archive)) fail(`Fablo snapshot file '${archive}' does not exist!`);

  const dir = getTempDir();
  run("tar", ["-xf", archive, "-C", dir]);
  run(path.join(dir, "fablo-target", "fabric-docker.sh"), ["clone-to", commandCallRoot, hookCommand]);
  console.log(`📦 Network restored from '${archive}'! Execute 'start' command to run it.`);
};

const startMcpServer = (networkDir) => {
  // MCP clients often start this process without a working directory, so the
  // network directory is required rather than defaulting to the current one.
  if (!networkDir || !fs.existsSync(networkDir) || !fs.statSync(networkDir).isDirectory()) {
    fail("Error: 'fablo mcp' requires an existing network directory: fablo mcp </path/to/network>");
  }
  if (!isOnPath("jaiph")) {
    fail(
      "Error: 'fablo mcp' requires Jaiph on the PATH.",
      "Install:",
      "  curl -fsSL https://jaiph.org/install | bash",
      "If jaiph is still not found, add ~/.local/bin to PATH.",
      "https://jaiph.org/how-to/install",
    );
  }

  // The MCP server runs Fablo as a shell script, so give it one that calls this file.
  const fabloScript = path.join(getTempDir(), "fablo.sh");
  fs.writeFileSync(
    fabloScript,
    `#!/usr/bin/env bash\nexec "${process.execPath}" "${fileURLToPath(import.meta.url)}" "$@"\n`,
    { mode: 0o755 },
  );

  run("bash", [path.join(packageDir, "mcp", "start.sh"), networkDir], {
    env: { ...process.env, FABLO_MCP_SCRIPT: process.env.FABLO_MCP_SCRIPT || fabloScript },
  });
};

const useVersion = (version) => {
  printSplash();
  console.log("Fablo is installed from npm.");
  console.log("To list available versions, run: npm view fablo versions");
  console.log(`To switch versions, run: npm install -g fablo@${version || "<version>"}`);
  if (version) process.exit(1);
};

if (!command) {
  printHelp();
  process.exit(1);
} else if (command === "help" || command === "--help") {
  printHelp();
} else if (command === "version") {
  await runGenerator(["version", ...params]);
} else if (command === "use") {
  useVersion(params[0]);
} else if (command === "init") {
  printSplash();
  await runGenerator(["init", ...params]);
} else if (command === "validate" || command === "extend-config") {
  const fabloConfig = resolveFabloConfig(params[0]);
  await runGenerator([command, fabloConfig], { fabloConfig });
} else if (command === "export-network-topology") {
  const fabloConfig = resolveFabloConfig(params[0]);
  const outputFile = path.resolve(params[1] || "network-topology.mmd");
  await runGenerator([command, fabloConfig, outputFile], { fabloConfig });
} else if (command === "generate") {
  await generateNetworkConfig(params[0], params[1]);
} else if (command === "up") {
  await networkUp(params[0]);
} else if (command === "prune") {
  networkPrune();
} else if (command === "recreate") {
  networkPrune();
  await networkUp(params[0]);
} else if (command === "snapshot") {
  createSnapshot(params[0]);
} else if (command === "restore") {
  restoreSnapshot(params[0], params[1]);
} else if (command === "mcp") {
  startMcpServer(params[0]);
} else {
  executeFabloCommand(command, ...params);
}
