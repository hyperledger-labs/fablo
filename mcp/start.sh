#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ] || [ ! -d "$1" ]; then
  echo "Usage: bash mcp/start.sh /absolute/path/to/network-directory" >&2
  exit 2
fi

mcp_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export FABLO_MCP_NETWORK_DIR="$(cd "$1" && pwd)"
export FABLO_MCP_ADAPTER="$mcp_dir/command.sh"
# An operator may select an installed Fablo shell script instead of this checkout.
export FABLO_MCP_SCRIPT="${FABLO_MCP_SCRIPT:-$mcp_dir/../fablo.sh}"
if [[ "$FABLO_MCP_SCRIPT" != /* ]] || [ ! -f "$FABLO_MCP_SCRIPT" ]; then
  echo "FABLO_MCP_SCRIPT must name an existing absolute path to a Fablo shell script." >&2
  exit 2
fi
export FABLO_MCP_SKILL="${FABLO_MCP_SKILL:-$mcp_dir/../skills/fablo/SKILL.md}"
if [ ! -f "$FABLO_MCP_SKILL" ]; then
  echo "FABLO_MCP_SKILL must name the Fablo skill file ($FABLO_MCP_SKILL not found)." >&2
  exit 2
fi
# The network_up agent gets a `fablo` limited to config commands. Jaiph passes
# agents only a few variables such as PATH, so the script path is baked in.
# The directory is outside the network directory, where the agent can edit.
agent_bin="$(mktemp -d "${TMPDIR:-/tmp}/fablo-mcp.XXXXXX")"
trap 'rm -rf "$agent_bin"' EXIT
printf '#!/usr/bin/env bash\nFABLO_MCP_SCRIPT=%q exec bash %q "$@"\n' \
  "$FABLO_MCP_SCRIPT" "$mcp_dir/agent-fablo.sh" >"$agent_bin/fablo"
chmod +x "$agent_bin/fablo"
export PATH="$agent_bin:$PATH"

# Fablo needs the host Docker daemon and persistent network files. Jaiph's
# default per-call container sandbox would isolate those files from later calls.
jaiph mcp --unsafe --workspace "$FABLO_MCP_NETWORK_DIR" "$mcp_dir/server.jh"
