#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ] || [ ! -d "$1" ]; then
  echo "Usage: bash mcp/start.sh /absolute/path/to/network-directory" >&2
  exit 2
fi

export FABLO_MCP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mcp_dir="$FABLO_MCP_DIR"
export FABLO_MCP_NETWORK_DIR="$(cd "$1" && pwd)"
# An operator may select an installed Fablo shell script instead of this checkout.
export FABLO_MCP_SCRIPT="${FABLO_MCP_SCRIPT:-$mcp_dir/../fablo.sh}"
if [[ "$FABLO_MCP_SCRIPT" != /* ]] || [ ! -f "$FABLO_MCP_SCRIPT" ]; then
  echo "FABLO_MCP_SCRIPT must name an existing absolute path to a Fablo shell script." >&2
  exit 2
fi
# Jaiph gives scripts only the variables granted here.
exec jaiph mcp --workspace "$FABLO_MCP_NETWORK_DIR" \
  --env FABLO_MCP_NETWORK_DIR --env FABLO_MCP_SCRIPT --env FABLO_MCP_DIR "$mcp_dir/server.jh"
