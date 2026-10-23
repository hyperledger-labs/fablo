#!/usr/bin/env bash
set -euo pipefail

fail() { echo "$*" >&2; exit 2; }
# Commands get no stdin: `fablo init` copies with `cp -i`, which must not wait
# for an answer.
fablo() { bash "${FABLO_MCP_SCRIPT:?Missing Fablo shell script}" "$@" </dev/null 2>&1; }

# Hooks run shell commands on the host, outside the client's own permission
# checks, so the MCP server refuses to start a network that has any.
rendered_hook() {
  [ ! -f "$1" ] || grep -vE '^(#.*|echo "Executing post-(generate|start) hook"|[[:space:]]*)$' "$1" || true
}
reject_rendered_hooks() {
  if [ -n "$(rendered_hook fablo-target/hooks/post-generate.sh)$(rendered_hook fablo-target/hooks/post-start.sh)" ]; then
    fail "The generated network in fablo-target has hooks, which run shell commands on the host. The MCP server does not run them. Prune the network and remove hooks from the config, or run Fablo yourself."
  fi
}
reject_config_hooks() {
  local extended
  extended="$(fablo extend-config)" || { echo "$extended"; fail "Cannot read the Fablo config."; }
  grep -q '"postGenerate"' <<<"$extended" || fail "Cannot read hooks from the Fablo config."
  if grep -Eq '"post(Generate|Start)": "[^"]' <<<"$extended"; then
    fail "The Fablo config sets hooks, which run shell commands on the host. The MCP server does not run them. Remove hooks.postGenerate and hooks.postStart, or run fablo up yourself."
  fi
}

case "${1:-}" in
  info|validate|up|start|stop|prune)
    [ "$#" -eq 1 ] || fail "This command takes no arguments."
    ;;
  init)
    [ "$#" -eq 2 ] || fail "Expected init <options>."
    read -ra options <<<"$2"
    for option in ${options[@]+"${options[@]}"}; do
      # dev adds a postGenerate hook, which network_up refuses to run.
      [[ "$option" =~ ^(node|ccaas|gateway|rest)$ ]] || fail "Unsupported init option: $option. Use node, ccaas, gateway, or rest."
    done
    ;;
  snapshot)
    [ "$#" -eq 2 ] && [ -n "$2" ] || fail "A non-empty target_path is required."
    ;;
  chaincode)
    [ "$#" -eq 4 ] && [ "$2" = upgrade ] || fail "Expected chaincode upgrade <name> <version>."
    # Generated Fabric scripts interpolate these identifiers into shell commands.
    [[ "$3" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.+-]*$ ]] || fail "Invalid chaincode name."
    [[ "$4" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.+-]*$ ]] || fail "Invalid chaincode version."
    ;;
  *) fail "Unsupported MCP command." ;;
esac

cd "${FABLO_MCP_NETWORK_DIR:?Start this server with mcp/start.sh}"

if [ "$1" = info ]; then
  echo "Network directory: $PWD"
  if [ -f fablo-config.json ] && [ -f fablo-config.yaml ]; then
    echo "Config: fablo-config.json (Fablo ignores fablo-config.yaml while both exist)"
  elif [ -f fablo-config.json ] || [ -f fablo-config.yaml ]; then
    echo "Config: $(ls fablo-config.json fablo-config.yaml 2>/dev/null)"
  else
    echo "Config: none. Create one with config_init, or write fablo-config.json in the network directory."
  fi
  if [ -d fablo-target ]; then
    echo "Generated network: fablo-target exists. Changing the config needs network_prune first."
  else
    echo "Generated network: none. network_up generates it from the config."
  fi
  exit 0
fi

# Atomic directory creation works on macOS and Linux without flock. Reject
# concurrent mutations rather than letting stop race with up or a snapshot.
lock_dir="$PWD/.fablo-mcp.lock"
mkdir "$lock_dir" 2>/dev/null || fail "Another MCP operation is active ($lock_dir). If a process was force-killed, remove the stale lock only after checking it has stopped."
trap 'rmdir "$lock_dir"' EXIT

case "$1" in
  init)
    if [ -f fablo-config.json ] || [ -f fablo-config.yaml ]; then
      fail "The network directory already has a Fablo config. Edit it instead."
    fi
    fablo init ${options[@]+"${options[@]}"}
    ;;
  up)
    fablo validate
    reject_config_hooks
    reject_rendered_hooks
    fablo up
    ;;
  start)
    reject_rendered_hooks
    fablo start
    ;;
  *) fablo "$@" ;;
esac
