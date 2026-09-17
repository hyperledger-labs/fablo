# Fablo MCP server

This MVP exposes Fablo's shell commands through [Jaiph's stdio MCP server](https://jaiph.org/how-to/mcp). It needs no agent credentials or npm dependencies.

Install [Jaiph](https://jaiph.org/) (tested with 0.13.0), and have Bash, Docker, and the usual Fablo prerequisites available on the host. Create a network directory containing your Fablo configuration and chaincode sources, or use an existing network directory.

Launch the server from an MCP client using this configuration, replacing the absolute paths:

```json
{
  "mcpServers": {
    "fablo": {
      "command": "bash",
      "args": [
        "/absolute/path/to/fablo/mcp/start.sh",
        "/absolute/path/to/network"
      ]
    }
  }
}
```

Ensure `jaiph` and Docker are on the client's `PATH`. The launcher works independently of the client's working directory and uses this checkout's `fablo.sh`. To select another installed Fablo shell script, set `FABLO_MCP_SCRIPT` to its absolute path in the MCP server's `env` configuration. Do not point it at the npm/oclif entrypoint, which provides the generator commands rather than the network lifecycle commands.

| Tool | Arguments (strings) | Fablo command |
| --- | --- | --- |
| `network_up` | `config_path` (use `""` for the default config) | `fablo up [config_path]` |
| `network_start` | None | `fablo start` |
| `network_stop` | None | `fablo stop` |
| `network_snapshot` | `target_path` | `fablo snapshot <target_path>` |
| `chaincode_install` | `chaincode_name`, `version` | `fablo chaincode install <name> <version>` |

For example, call `network_up` with `{"config_path":""}` to generate and start a network, including its configured channels and chaincodes. Use `network_start` to resume it after `network_stop`. Install an individual configured chaincode with `{"chaincode_name":"kv","version":"1.0"}`. Names and versions accept letters, digits, dots, underscores, plus signs, and hyphens, starting with a letter or digit.

Paths are relative to the configured network directory unless absolute. A snapshot target of `backup` produces `backup.fablo.tar.gz`; Fablo refuses to overwrite an existing archive. Snapshot support depends on the network provider; the adapter preserves the existing CLI behavior. Configure a generous tool timeout in your client: initial setup and chaincode builds can take several minutes.

The launcher explicitly selects Jaiph's `--unsafe` host execution mode because Fablo operates the host Docker daemon and persistent network files. Connected clients can run these five operations with the launching user's permissions, including hooks configured in the network. Use a trusted configuration and a dedicated server entry for each network. This MVP serves local stdio only.

Command output becomes MCP text content; command failures become tool results with `isError: true`. Jaiph stores execution records under the network directory's `.jaiph/runs/`. A `.fablo-mcp.lock` directory rejects overlapping MCP mutations of the same network; it does not coordinate commands run manually outside MCP. After a forced kill, remove a stale lock only once the operation has stopped. Cancellation does not roll back changes already made by Fablo.

Validate the workflow and run the protocol integration test from this checkout:

```bash
jaiph compile mcp/server.jh
jaiph format --check mcp/server.jh
node --test mcp/server.test.cjs
```

The test requires Node.js 18+ and Jaiph. It launches the real MCP server against a fake Fablo script in a temporary directory, checks tool discovery and routing, argument validation and quoting, lock handling, and failure propagation. It does not start Docker. Jaiph may create audit keys in `~/.jaiph` during the test. Real Fabric network operations remain covered by the existing network test suites rather than this protocol test.
