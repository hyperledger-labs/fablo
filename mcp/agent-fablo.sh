#!/usr/bin/env bash
set -euo pipefail

# The network_up agent runs this as `fablo` (see start.sh). The agent prepares
# and checks the config; the MCP tools own every network lifecycle command.
case "${1:-}" in
  init|validate|extend-config) exec bash "${FABLO_MCP_SCRIPT:?Start this server with mcp/start.sh}" "$@" ;;
  *) echo "Only fablo init, validate, and extend-config are available here." >&2; exit 2 ;;
esac
