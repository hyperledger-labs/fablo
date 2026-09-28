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

`fablo mcp` lets an agent start and manage a network through MCP tools. The agent can describe the network it wants in plain language. Fablo then writes and validates the config with the help of the Fablo skill, and starts the network. The agent can also stop, resume, snapshot, and prune the network, and install chaincodes.

It requires [Jaiph](https://jaiph.org/) on the `PATH`. Starting a network from a description also requires the signed-in Claude CLI. To add the server to Claude Code:

```bash
claude mcp add fablo -- /absolute/path/to/fablo mcp /absolute/path/to/network
```

Use one server for each network directory. For other clients, the tools, and the safety model, see the [MCP server documentation](https://github.com/hyperledger-labs/fablo/blob/main/mcp/README.md).
