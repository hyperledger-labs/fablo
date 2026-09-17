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

# Fablo needs the host Docker daemon and persistent network files. Jaiph's
# default per-call container sandbox would isolate those files from later calls.
exec jaiph mcp --unsafe --workspace "$FABLO_MCP_NETWORK_DIR" "$mcp_dir/server.jh"
