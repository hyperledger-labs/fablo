# Fablo MCP server

`fablo mcp` serves a Fablo network directory to MCP clients over stdio, through [Jaiph's MCP server](https://jaiph.org/how-to/mcp). Each tool runs one Fablo command, and every command in `fablo --help` has a tool except `mcp` itself. The connected agent writes the config itself, validates it, and runs the network.

## Requirements

- Fablo, Docker, and Bash on the host.
- [Jaiph](https://jaiph.org/) on the `PATH` (tested with 0.15.0). Install it with `curl -fsSL https://jaiph.org/install | bash`; if `jaiph` is still not found, add `~/.local/bin` to the `PATH`. See [installing Jaiph](https://jaiph.org/how-to/install).
- An MCP client that can edit files in the network directory, such as Claude Code, Cursor, or Codex. The server gives it the [Fablo skill](../skills/fablo/SKILL.md) and the config schema through tools, so nothing else needs to be installed in the client.

## Connect a client

Run `fablo mcp` with the network directory, as an absolute path. The directory is required and must exist: MCP clients often start the server without a working directory, so there is no default.

### Claude Code

```bash
claude mcp add fablo -- /absolute/path/to/fablo mcp /absolute/path/to/network
```

Add `--scope user` to make the server available in every project. Claude Code needs no timeout change: its default tool timeout for stdio servers is about 28 hours.

### Cursor

Add the server to `.cursor/mcp.json` in the project, or to `~/.cursor/mcp.json` for all projects. Servers can be toggled under Customize in the sidebar:

```json
{
  "mcpServers": {
    "fablo": {
      "command": "/absolute/path/to/fablo",
      "args": ["mcp", "/absolute/path/to/network"]
    }
  }
}
```

### Codex

```bash
codex mcp add fablo -- /absolute/path/to/fablo mcp /absolute/path/to/network
```

Or add it to `~/.codex/config.toml`. The timeouts are in seconds; the defaults are too short for `network_up`:

```toml
[mcp_servers.fablo]
command = "/absolute/path/to/fablo"
args = ["mcp", "/absolute/path/to/network"]
startup_timeout_sec = 120
tool_timeout_sec = 900
```

### Other clients

Any client that launches stdio MCP servers takes the same command and arguments in its configuration, as in the Cursor example above.

By default the server runs in a temporary directory: `fablo mcp` unpacks it, with the Fablo skill and the config schema, from the Fablo Docker image for its version, so it always matches the installed script. Use one server entry for each network. Configure a generous tool timeout in your client: starting a network and building chaincodes can take several minutes.

## Tools

All arguments are strings. An empty optional argument means the Fablo default: the default config file, `fablo-target`, and so on. Paths are relative to the network directory.

### Config

| Tool | Arguments | Runs |
| --- | --- | --- |
| `network_info` | None | Shows the network directory, its config file, and whether `fablo-target` exists. |
| `config_instructions` | None | Returns the [Fablo skill](../skills/fablo/SKILL.md): how to write, validate, and run a config. |
| `config_schema` | None | Returns the config JSON schema for this Fablo version. |
| `config_init` | `options`, `overrides` | `fablo init <options> [--set <path>=<value> ...]`. `options` takes any of `node`, `dev`, `ccaas`, `gateway`, and `rest`, or `fabric-x` alone. `dev` only matters together with `node`: the sample chaincode runs as CCaaS and reloads when its source changes. `overrides` takes one `<path>=<value>` per line. Fails if a config exists. |
| `config_validate` | `config_path` | `fablo validate [config]` |
| `config_extend` | `config_path` | `fablo extend-config [config]` |
| `config_export_topology` | `config_path`, `output_path` | `fablo export-network-topology [config [output]]` |

### Network

| Tool | Arguments | Runs |
| --- | --- | --- |
| `network_generate` | `config_path`, `target_path` | A hooks check, then `fablo generate [config [target]]`. |
| `network_up` | `config_path` | `fablo validate`, hooks checks, then `fablo up [config]`. |
| `network_start` | None | A hooks check, then `fablo start`. |
| `network_stop` | None | `fablo stop` |
| `network_down` | None | `fablo down`. Destroys the ledger state. |
| `network_reset` | None | `fablo reset`. Destroys the ledger state. |
| `network_prune` | None | `fablo prune`. Destroys the network state and generated files. |
| `network_recreate` | `config_path` | `fablo validate`, a hooks check, then `fablo recreate [config]`. Destroys the network state. |
| `network_snapshot` | `path` | `fablo snapshot <path>` |
| `network_restore` | `path` | `fablo restore <path>`, without the optional hook command, which is a host shell command. |

### Chaincodes, channels, and namespaces

| Tool | Arguments | Runs |
| --- | --- | --- |
| `chaincodes_install` | None | `fablo chaincodes install` |
| `chaincode_install` | `chaincode_name`, `version` | `fablo chaincode install <name> <version>` |
| `chaincode_upgrade` | `chaincode_name`, `version` | `fablo chaincode upgrade <name> <version>` |
| `chaincode_dev` | `chaincode_name` | `fablo chaincode dev <name>` |
| `chaincode_invoke` | `peers`, `channel_name`, `chaincode_name`, `command`, `transient` | `fablo chaincode invoke <peers> <channel> <name> <command> [transient]` |
| `chaincode_query` | `peer`, `channel_name`, `chaincode_name`, `command`, `transient` | `fablo chaincode query <peer> <channel> <name> <command> [transient]` |
| `chaincodes_list` | `peer`, `channel_name` | `fablo chaincodes list <peer> <channel>` |
| `channel_help` | None | `fablo channel --help` |
| `channel_list` | `org`, `peer` | `fablo channel list <org> <peer>` |
| `channel_getinfo` | `channel_name`, `org`, `peer` | `fablo channel getinfo <channel> <org> <peer>` |
| `channel_fetch` | `block`, `channel_name`, `org`, `peer`, `file` | `fablo channel fetch <config\|newest\|oldest\|number> <channel> <org> <peer> [file]` |
| `namespace_list` | None | `fablo namespace list` (Fabric-X) |
| `namespace_init` | `name` | `fablo namespace init [name]` (Fabric-X) |

### Fablo

| Tool | Arguments | Runs |
| --- | --- | --- |
| `fablo_help` | None | `fablo help` |
| `fablo_version` | `verbose` | `fablo version [--verbose]`, with `verbose` set to `true` |
| `fablo_use` | `version` | `fablo use [version]`. Switches the Fablo script this server runs; restart the server afterwards. |

### Start a network

The server runs no agent. The connected agent describes the network by writing the config:

1. `network_info` shows where the config goes and whether a network already exists.
2. `config_instructions` and `config_schema` tell the agent how to write the config.
3. `config_init` creates a starter `fablo-config.json`, for example with `node rest`. The agent can also write the config from scratch.
4. The agent edits the config in the network directory, and calls `config_validate` until it passes.
5. `network_up` generates the network, starts it, creates channels, and deploys chaincodes.

To change a network that `fablo-target` already holds, use `network_recreate`, or prune it first with `network_prune`.

### Hooks

`hooks.postGenerate` and `hooks.postStart` run shell commands on the host. Through MCP they would run outside the client's own permission checks, so the server refuses to start a network that has them: `network_up` checks the config and any generated hooks in `fablo-target`, `network_generate` and `network_recreate` check the config, and `network_start` checks the generated hooks. To use other hooks, run Fablo yourself.

The one exception is the hook that `fablo init node dev` writes, `npm i --prefix ./chaincodes/chaincode-kv-node`, which installs the dependencies of the sample chaincode. The server allows exactly that `postGenerate` command, so a `config_init` starter with `node dev` starts through `network_up`. npm must be installed on the host.

## Behavior and safety

Paths must be relative to the network directory and stay inside it: absolute paths, paths that start with `-`, paths that contain `..`, and paths through a symlink to another directory are rejected. Snapshots hold identities and private keys, so the server checks the final archive path. A snapshot path of `backup` produces `backup.fablo.tar.gz`, and Fablo refuses to overwrite an existing archive.

Chaincode, channel, organization, peer, and namespace names, chaincode versions, and Fablo versions accept letters, digits, dots, underscores, plus signs, and hyphens, starting with a letter or digit, because generated Fabric scripts interpolate them into shell commands. Peer lists also accept commas. Chaincode commands and transient data are passed as single arguments, so they can hold any JSON.

Fablo passes `init` arguments and the topology output path through a shell inside its container. `config_init` overrides therefore accept only letters, digits, and `_ . : / @ + , -` in values, and `config_export_topology` output paths only letters, digits, and `_ . / -`.

Jaiph runs the tools on the host with no sandbox, because Fablo drives the host Docker daemon and keeps network files between calls. Connected clients can run these tools with your permissions. Only use configs and chaincodes you trust.

Command output becomes the tool result, and a failed command returns a result with `isError: true`. Jaiph keeps a record of each call under the network directory's `.jaiph/runs/`. A `.fablo-mcp.lock` directory stops two MCP commands from changing the same network at once. It does not cover Fablo commands you run yourself. After a forced kill, remove a stale lock only once the operation has stopped. Canceling a call does not undo changes Fablo already made.

## Develop and test

In a Fablo checkout, run the server without the Docker image:

```bash
bash mcp/start.sh /absolute/path/to/network
```

It uses the checkout's `fablo.sh`. Set `FABLO_MCP_SCRIPT` to the absolute path of another Fablo script to use that instead.

Validate the workflow and run the tests:

```bash
jaiph compile mcp/server.jh
jaiph format --check mcp/server.jh
node --test mcp/server.test.cjs
```

The Node.js test (Node.js 18+) starts the real MCP server against a fake Fablo script. It checks tool discovery, command routing for every tool, argument and path validation, quoting, the hooks checks, locking, failures, and that `fablo mcp` requires a network directory. It calls no Docker. CI runs these checks, and `lint.sh` runs shellcheck on `mcp/command.sh` and `mcp/start.sh`. Jaiph may create audit keys in `~/.jaiph`.
