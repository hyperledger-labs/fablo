# Fablo MCP server

`fablo mcp` serves a Fablo network directory to MCP clients over stdio, through [Jaiph's MCP server](https://jaiph.org/how-to/mcp). An agent can describe the network it wants in plain language, and then stop, resume, snapshot, and prune it.

## Requirements

- Fablo, Docker, and Bash on the host.
- [Jaiph](https://jaiph.org/) on the `PATH` (tested with 0.13.0).
- The [Claude CLI](https://docs.anthropic.com/en/docs/claude-code), signed in, for `network_up` with instructions. The other tools call no agent.

## Connect a client

Run `fablo mcp` with the network directory. It defaults to the current directory, but most clients do not set one, so pass an absolute path. With Claude Code:

```bash
claude mcp add fablo -- /absolute/path/to/fablo mcp /absolute/path/to/network
```

Other clients take the same command in their configuration:

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

`fablo mcp` reads the server and the [Fablo skill](../skills/fablo/SKILL.md) from the Fablo Docker image for its version, so they always match the installed script. Use one server entry for each network. Configure a generous tool timeout in your client: starting a network and building chaincodes can take several minutes.

## Tools

All arguments are strings.

| Tool | Arguments | What it does |
| --- | --- | --- |
| `network_up` | `instructions` | Prepares the config from instructions, then runs `fablo up`. |
| `network_start` | None | `fablo start` |
| `network_stop` | None | `fablo stop` |
| `network_prune` | None | `fablo prune`. Destroys the network state. |
| `network_snapshot` | `target_path` | `fablo snapshot <target_path>` |
| `chaincode_install` | `chaincode_name`, `version` | `fablo chaincode install <name> <version>` |

Every tool except `network_up` with instructions wraps a Fablo command directly.

### Start a network from instructions

Call `network_up` with a description, for example:

```json
{"instructions": "Two organizations with two peers each, a RAFT orderer with three nodes, one channel, and the sample Node.js chaincode"}
```

An agent reads the Fablo skill and writes `fablo-config.json` in the network directory, running `fablo init` for samples when that helps. It reports ready only after `fablo validate` passes. Fablo then runs `fablo up`, which generates the network, starts it, creates channels, and deploys chaincodes. The result starts with the agent's summary of the network.

To start the config already in the network directory without an agent, pass `{"instructions": ""}`.

The agent does not start or change a network that already exists. If `fablo-target` is present and its config does not satisfy the instructions, the call fails with the reason. Use `network_prune` first to replace the network.

The agent runs with limited permissions. It can edit files only in the network directory, and its `fablo` command runs only `init`, `validate`, and `extend-config`. It is told never to add `hooks`, because they run shell commands on the host, but this rule is not enforced. Check the config before calling `network_up` again with it.

Peer dev mode is not handled yet: the agent does not start local chaincode processes.

To use a different agent, set `JAIPH_AGENT_BACKEND` in the server's `env` configuration, for example to `cursor`. The permission limits above are Claude CLI flags, so apply equivalent limits with `JAIPH_AGENT_CURSOR_FLAGS`.

## Behavior and safety

Paths are relative to the network directory unless absolute. A snapshot target of `backup` produces `backup.fablo.tar.gz`, and Fablo refuses to overwrite an existing archive. Chaincode names and versions accept letters, digits, dots, underscores, plus signs, and hyphens, starting with a letter or digit.

The server runs in Jaiph's `--unsafe` host mode, because Fablo drives the host Docker daemon and keeps network files between calls. Connected clients can run these tools with your permissions, including any hooks already in the network's config. Only use configs you trust.

Command output becomes the tool result, and a failed command returns a result with `isError: true`. Jaiph keeps a record of each call under the network directory's `.jaiph/runs/`. A `.fablo-mcp.lock` directory stops two MCP commands from changing the same network at once. It does not cover Fablo commands you run yourself. After a forced kill, remove a stale lock only once the operation has stopped. Canceling a call does not undo changes Fablo already made.

## Develop and test

In a Fablo checkout, run the server without the Docker image:

```bash
bash mcp/start.sh /absolute/path/to/network
```

It uses the checkout's `fablo.sh` and `skills/fablo/SKILL.md`. Set `FABLO_MCP_SCRIPT` or `FABLO_MCP_SKILL` to absolute paths to use others.

Validate the workflow and run the tests:

```bash
jaiph compile mcp/server.jh
jaiph format --check mcp/server.jh mcp/server.test.jh
jaiph test mcp/server.test.jh
node --test mcp/server.test.cjs
```

The Jaiph test mocks the agent and checks when `network_up` calls it and when it starts the network. The Node.js test (Node.js 18+) starts the real MCP server against a fake Fablo script. It checks tool discovery, command routing, argument validation and quoting, locking, failures, and the limits on the agent's `fablo` command. Neither test calls an agent or Docker. Jaiph may create audit keys in `~/.jaiph`.
