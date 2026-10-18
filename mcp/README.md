# Fablo MCP server

`fablo mcp` serves a Fablo network directory to MCP clients over stdio, through [Jaiph's MCP server](https://jaiph.org/how-to/mcp). Each tool runs one Fablo command: the connected agent writes the config itself, validates it, starts the network, and then stops, resumes, snapshots, and prunes it.

## Requirements

- Fablo, Docker, and Bash on the host.
- [Jaiph](https://jaiph.org/) on the `PATH` (tested with 0.15.0).
- An MCP client that can edit files in the network directory, such as Claude Code, Cursor, or Codex. Install the [Fablo skill](../skills/fablo/SKILL.md) in it, so it knows how to write Fablo configs.

## Connect a client

Run `fablo mcp` with the network directory. It defaults to the current directory, but most clients do not set one, so pass an absolute path.

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

By default the server runs in a temporary directory: `fablo mcp` unpacks it from the Fablo Docker image for its version, so it always matches the installed script. Use one server entry for each network. Configure a generous tool timeout in your client: starting a network and building chaincodes can take several minutes.

## Tools

All arguments are strings.

| Tool | Arguments | What it does |
| --- | --- | --- |
| `network_info` | None | Shows the network directory, its config file, and whether `fablo-target` exists. |
| `config_init` | `options` | `fablo init <options>`, with any of `node`, `ccaas`, `gateway`, and `rest`. Fails if a config exists. |
| `config_validate` | None | `fablo validate` |
| `network_up` | None | `fablo validate`, a hooks check, then `fablo up`. |
| `network_start` | None | A hooks check, then `fablo start`. |
| `network_stop` | None | `fablo stop` |
| `network_prune` | None | `fablo prune`. Destroys the network state. |
| `network_snapshot` | `target_path` | `fablo snapshot <target_path>` |
| `chaincode_upgrade` | `chaincode_name`, `version` | `fablo chaincode upgrade <name> <version>` |

### Start a network

The server runs no agent. The connected agent describes the network by writing the config:

1. `network_info` shows where the config goes and whether a network already exists.
2. `config_init` creates a starter `fablo-config.json`, for example with `node rest`. The agent can also write the config from scratch.
3. The agent edits the config in the network directory, and calls `config_validate` until it passes.
4. `network_up` generates the network, starts it, creates channels, and deploys chaincodes.

To change a network that `fablo-target` already holds, prune it first with `network_prune`.

### Hooks

`hooks.postGenerate` and `hooks.postStart` run shell commands on the host. Through MCP they would run outside the client's own permission checks, so the server refuses to start a network that has them: `network_up` checks the config and any generated hooks in `fablo-target`, and `network_start` checks the generated hooks. To use hooks, run `fablo up` and `fablo start` yourself. For the same reason, `config_init` does not offer `dev`, which adds a `postGenerate` hook.

Peer dev mode is not handled yet.

## Behavior and safety

Paths are relative to the network directory unless absolute. A snapshot target of `backup` produces `backup.fablo.tar.gz`, and Fablo refuses to overwrite an existing archive. Chaincode names and versions accept letters, digits, dots, underscores, plus signs, and hyphens, starting with a letter or digit.

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

The Node.js test (Node.js 18+) starts the real MCP server against a fake Fablo script. It checks tool discovery, command routing, argument validation and quoting, the hooks checks, locking, and failures. It calls no Docker. Jaiph may create audit keys in `~/.jaiph`.
