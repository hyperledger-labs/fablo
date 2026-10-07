---
layout: doc
title: AI agents
---


# Use Fablo with AI Agents

**Outline**
1. [Install the Fablo Skill](#install-the-fablo-skill)
2. [Connect the MCP Server](#connect-the-mcp-server)


## Install the Fablo Skill

The Fablo skill teaches coding agents such as Claude Code, Cursor, and Codex how to configure, validate, run, and troubleshoot Fablo networks. It also tells them to ask before destructive operations and to keep keys and snapshots private.

Install it with the [skills CLI](https://github.com/vercel-labs/skills), which detects your agents and adds the skill to each of them:

```bash
npx skills add hyperledger-labs/fablo --skill fablo
```

By default the skill is added to the current project. Add `-g` to add it for your user instead, or `-a <agent>` to choose the agent, for example `-a claude-code`. To update it later, run `npx skills update`.

The skill is a single file, [`skills/fablo/SKILL.md`](https://github.com/hyperledger-labs/fablo/blob/main/skills/fablo/SKILL.md). If your agent is not supported by the skills CLI, point the agent at that file.


## Connect the MCP Server

`fablo mcp` lets an agent start and manage a network through MCP tools. The agent can describe the network it wants in plain language. Fablo then writes and validates the config with the help of the Fablo skill, and starts the network. The agent can also stop, resume, snapshot, and prune the network, and upgrade chaincodes.

It requires [Jaiph](https://jaiph.org/) on the `PATH`. By default the server runs in a temporary directory: `fablo mcp` unpacks it from the Fablo Docker image for its version, so it always matches the installed script.

**Note:** the MCP server works with Claude only. The agent behind `network_up` is the Claude CLI, so it must be installed and signed in on the host, whichever MCP client you connect from.

Use one server for each network directory, and pass absolute paths, because most clients do not set a working directory. Starting a network and building chaincodes can take several minutes, so give the tools a generous timeout.

### Claude Code

```bash
claude mcp add fablo -- /absolute/path/to/fablo mcp /absolute/path/to/network
```

Add `--scope user` to make the server available in every project. Claude Code needs no timeout change: its default tool timeout for stdio servers is about 28 hours.

### Cursor

Add the server to `.cursor/mcp.json` in the project, or to `~/.cursor/mcp.json` for all projects:

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

Cursor loads it on the next start. Servers can be toggled under Customize in the sidebar.

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

For the tools and the safety model, see the [MCP server documentation](https://github.com/hyperledger-labs/fablo/blob/main/mcp/README.md).
