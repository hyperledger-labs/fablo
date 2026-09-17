#!/usr/bin/env bash
set -euo pipefail

fail() { echo "$*" >&2; exit 2; }
case "${1:-}" in
  up)
    [ "$#" -eq 2 ] || fail "Expected config_path (empty string selects the default)."
    if [ -z "$2" ]; then set -- up; fi
    ;;
  start|stop)
    [ "$#" -eq 1 ] || fail "This command takes no arguments."
    ;;
  snapshot)
    [ "$#" -eq 2 ] && [ -n "$2" ] || fail "A non-empty target_path is required."
    ;;
  chaincode)
    [ "$#" -eq 4 ] && [ "$2" = install ] || fail "Expected chaincode install <name> <version>."
    # Generated Fabric scripts interpolate these identifiers into shell commands.
    [[ "$3" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.+-]*$ ]] || fail "Invalid chaincode name."
    [[ "$4" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.+-]*$ ]] || fail "Invalid chaincode version."
    ;;
  *) fail "Unsupported MCP command." ;;
esac

cd "${FABLO_MCP_NETWORK_DIR:?Start this server with mcp/start.sh}"
# Atomic directory creation works on macOS and Linux without flock. Reject
# concurrent mutations rather than letting stop race with up or a snapshot.
lock_dir="$PWD/.fablo-mcp.lock"
mkdir "$lock_dir" 2>/dev/null || fail "Another MCP operation is active ($lock_dir). If a process was force-killed, remove the stale lock only after checking it has stopped."
trap 'rmdir "$lock_dir"' EXIT
bash "${FABLO_MCP_SCRIPT:?Missing Fablo shell script}" "$@" 2>&1
