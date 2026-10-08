# Fablo MCP server

`fablo mcp` serves a Fablo network directory to MCP clients over stdio, through [Jaiph's MCP server](https://jaiph.org/how-to/mcp). An agent can describe the network it wants in plain language, and then stop, resume, snapshot, and prune it.

## Requirements

- Fablo, Docker, and Bash on the host.
- [Jaiph](https://jaiph.org/) on the `PATH` (tested with 0.15.0).
- The [Claude CLI](https://docs.anthropic.com/en/docs/claude-code), signed in, for `network_up`. The other tools call no agent.

## Connect a client

Run `fablo mcp` with the network directory. It defaults to the current directory, but most clients do not set one, so pass an absolute path.

> **Note:** the MCP server works with Claude only. The agent behind `network_up` is the Claude CLI, so it must be installed and signed in on the host, whichever MCP client you connect from.

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
| `network_up` | `instructions` | Prepares the config from instructions, then runs `fablo up`. |
| `network_start` | None | `fablo start` |
| `network_stop` | None | `fablo stop` |
| `network_prune` | None | `fablo prune`. Destroys the network state. |
| `network_snapshot` | `target_path` | `fablo snapshot <target_path>` |
| `chaincode_upgrade` | `chaincode_name`, `version` | `fablo chaincode upgrade <name> <version>` |

Every tool except `network_up` wraps a Fablo command directly.

### Start a network from instructions

Call `network_up` with a description, for example:

```json
{"instructions": "Two organizations with two peers each, a RAFT orderer with three nodes, one channel, and the sample Node.js chaincode"}
```

An agent follows the [Fablo skill](../skills/fablo/SKILL.md), which is embedded in the server, and writes `fablo-config.json` in the network directory, running `fablo init` for samples when that helps. It reports ready only after `fablo validate` passes. Fablo then runs `fablo up`, which generates the network, starts it, creates channels, and deploys chaincodes. The result starts with the agent's summary of the network.

`network_up` always needs instructions, so it never starts a config that nobody described. If the directory already has a config, the agent keeps it only when it satisfies the instructions, and edits it otherwise.

The agent does not change a network that already exists. If `fablo-target` is present and its config does not satisfy the instructions, the call fails with the reason. Use `network_prune` first to replace the network.

The agent runs with limited permissions. It can edit files only in the network directory, and its `fablo` command runs only `init`, `validate`, and `extend-config`. It is told never to add `hooks`, because they run shell commands on the host, but this rule is not enforced. Check the config before calling `network_up` again with it.

Peer dev mode is not handled yet: the agent does not start local chaincode processes.

## Behavior and safety

Paths are relative to the network directory unless absolute. A snapshot target of `backup` produces `backup.fablo.tar.gz`, and Fablo refuses to overwrite an existing archive. Chaincode names and versions accept letters, digits, dots, underscores, plus signs, and hyphens, starting with a letter or digit.

Jaiph runs the tools on the host with no sandbox, because Fablo drives the host Docker daemon and keeps network files between calls. Connected clients can run these tools with your permissions, including any hooks already in the network's config. Only use configs you trust.

Command output becomes the tool result, and a failed command returns a result with `isError: true`. Jaiph keeps a record of each call under the network directory's `.jaiph/runs/`. A `.fablo-mcp.lock` directory stops two MCP commands from changing the same network at once. It does not cover Fablo commands you run yourself. After a forced kill, remove a stale lock only once the operation has stopped. Canceling a call does not undo changes Fablo already made.

## Develop and test

In a Fablo checkout, run the server without the Docker image:

```bash
bash mcp/start.sh /absolute/path/to/network
```

It uses the checkout's `fablo.sh`. Set `FABLO_MCP_SCRIPT` to the absolute path of another Fablo script to use that instead.

The server embeds the skill as `mcp/skill.jh`, generated from `skills/fablo/SKILL.md`. After changing the skill, regenerate it:

```bash
bash mcp/embed-skill.sh > mcp/skill.jh
```

Validate the workflow and run the tests:

```bash
jaiph compile mcp/server.jh
jaiph format --check mcp/server.jh mcp/server.test.jh mcp/skill.jh
jaiph test mcp/server.test.jh
node --test mcp/server.test.cjs
```

The Jaiph test mocks the agent. It checks what `network_up` sends to the agent and when it starts the network. The Node.js test (Node.js 18+) starts the real MCP server against a fake Fablo script. It checks tool discovery, command routing, argument validation and quoting, locking, failures, the limits on the agent's `fablo` command, and that `mcp/skill.jh` matches the skill. Neither test calls an agent or Docker. Jaiph may create audit keys in `~/.jaiph`.
