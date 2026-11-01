#!/usr/bin/env bash
set -euo pipefail

fail() { echo "$*" >&2; exit 2; }
# Commands get no stdin: `fablo init` copies with `cp -i`, which must not wait
# for an answer.
fablo() { bash "${FABLO_MCP_SCRIPT:?Missing Fablo shell script}" "$@" </dev/null 2>&1; }
arguments() { [ "$1" -eq "$2" ] || fail "Expected $3."; }

# Generated Fabric scripts interpolate identifiers into shell commands.
id_pattern='^[a-zA-Z0-9][a-zA-Z0-9_.+-]*$'
identifier() { [[ "$2" =~ $id_pattern ]] || fail "Invalid $1: $2"; }

# Paths stay inside the network directory. Snapshots hold identities and keys.
relative_path() {
  [ -n "$2" ] || fail "A non-empty $1 is required."
  [[ "$2" != /* ]] || fail "The $1 must be relative to the network directory."
  [[ "$2" != -* ]] || fail "The $1 must not start with -."
  [[ "/$2/" != */../* ]] || fail "The $1 must not contain '..'."
  local parent
  parent="$(dirname "$2")"
  if [ -d "$parent" ]; then
    case "$(cd "$parent" && pwd -P)/" in
      "$(pwd -P)/"*) ;;
      *) fail "The $1 must stay inside the network directory." ;;
    esac
  fi
}
optional_path() { [ -z "$2" ] || relative_path "$1" "$2"; }
# Fablo appends .fablo.tar.gz unless the path already ends in tar.gz.
archive_path() {
  [ -n "$2" ] || fail "A non-empty $1 is required."
  if [[ "$2" == *tar.gz ]]; then relative_path "$1" "$2"; else relative_path "$1" "$2.fablo.tar.gz"; fi
}

# Hooks run shell commands on the host, outside the client's own permission
# checks, so the MCP server refuses to start a network that has any. The one
# exception is the hook `fablo init node dev` writes itself.
dev_hook='npm i --prefix ./chaincodes/chaincode-kv-node'
hooks_refused="hooks, which run shell commands on the host. The MCP server runs only the postGenerate hook from 'fablo init node dev' ($dev_hook)."
hook_value() {
  local lines
  lines="$(sed -n "s/^    \"$1\": \"\(.*\)\",\{0,1\}\$/=\1/p" <<<"$2")"
  [[ "$lines" == =* && "$lines" != *$'\n'* ]] || fail "Cannot read hooks from the Fablo config."
  printf '%s' "${lines#=}"
}
reject_config_hooks() {
  local extended post_generate post_start
  extended="$(fablo extend-config "$1")" || { echo "$extended"; fail "Cannot read the Fablo config."; }
  post_generate="$(hook_value postGenerate "$extended")" || exit 2
  post_start="$(hook_value postStart "$extended")" || exit 2
  if [ -n "$post_start" ] || { [ -n "$post_generate" ] && [ "$post_generate" != "$dev_hook" ]; }; then
    fail "The Fablo config sets $hooks_refused Remove other hooks, or run Fablo yourself."
  fi
}
rendered_hook() {
  [ ! -f "$1" ] || grep -vE '^(#.*|echo "Executing post-(generate|start) hook"|[[:space:]]*)$' "$1" || true
}
reject_rendered_hooks() {
  local post_generate
  post_generate="$(rendered_hook fablo-target/hooks/post-generate.sh)"
  if [ -n "$(rendered_hook fablo-target/hooks/post-start.sh)" ] || { [ -n "$post_generate" ] && [ "$post_generate" != "$dev_hook" ]; }; then
    fail "The generated network in fablo-target has $hooks_refused Prune the network and remove the hooks from the config, or run Fablo yourself."
  fi
}

cd "${FABLO_MCP_NETWORK_DIR:?Start this server with mcp/start.sh}"
command=("$@")

case "${1:-}" in
  info | skill | schema | help | down | start | stop | reset | prune)
    arguments "$#" 1 "no arguments"
    ;;
  validate | extend-config | up | recreate)
    arguments "$#" 2 "$1 <config_path>"
    optional_path "config_path" "$2"
    ;;
  generate)
    arguments "$#" 3 "generate <config_path> <target_path>"
    optional_path "config_path" "$2"
    optional_path "target_path" "$3"
    ;;
  export-network-topology)
    arguments "$#" 3 "export-network-topology <config_path> <output_path>"
    optional_path "config_path" "$2"
    optional_path "output_path" "$3"
    # Fablo passes the output path through a shell inside its container.
    [[ "$3" =~ ^[A-Za-z0-9_./-]*$ ]] || fail "The output_path may contain only letters, digits, '_', '.', '/', and '-'."
    ;;
  init)
    arguments "$#" 3 "init <options> <overrides>"
    command=(init)
    read -ra options <<<"$2"
    for option in ${options[@]+"${options[@]}"}; do
      [[ "$option" =~ ^(node|dev|ccaas|gateway|rest|fabric-x)$ ]] || fail "Unsupported init option: $option. Use node, dev, ccaas, gateway, rest, or fabric-x."
      command+=("$option")
    done
    while IFS= read -r override; do
      [ -n "$override" ] || continue
      # Fablo passes init arguments through a shell inside its container.
      [[ "$override" =~ ^[A-Za-z0-9_.]+(\[[0-9]+\][A-Za-z0-9_.]*)*=[A-Za-z0-9_.:/@+,-]*$ ]] || fail "Invalid override: $override. Use <path>=<value>, with letters, digits, and _ . : / @ + , - in the value."
      command+=(--set "$override")
    done <<<"$3"
    ;;
  snapshot | restore)
    arguments "$#" 2 "$1 <path>"
    archive_path "path" "$2"
    ;;
  chaincodes)
    case "${2:-}" in
      install) arguments "$#" 2 "chaincodes install" ;;
      list)
        arguments "$#" 4 "chaincodes list <peer> <channel>"
        identifier "peer" "$3"
        identifier "channel" "$4"
        ;;
      *) fail "Expected chaincodes install or chaincodes list." ;;
    esac
    ;;
  chaincode)
    case "${2:-}" in
      install | upgrade)
        arguments "$#" 4 "chaincode $2 <name> <version>"
        identifier "chaincode name" "$3"
        identifier "chaincode version" "$4"
        ;;
      dev)
        arguments "$#" 3 "chaincode dev <name>"
        identifier "chaincode name" "$3"
        ;;
      invoke | query)
        # The command and transient data reach the peer CLI as quoted arguments.
        arguments "$#" 7 "chaincode $2 <peers> <channel> <name> <command> <transient>"
        [[ "$3" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.,-]*$ ]] || fail "Invalid peers: $3"
        [ "$2" = invoke ] || identifier "peer" "$3"
        identifier "channel" "$4"
        identifier "chaincode name" "$5"
        [ -n "$6" ] || fail "A non-empty chaincode command is required."
        ;;
      *) fail "Unsupported chaincode command." ;;
    esac
    ;;
  channel)
    case "${2:-}" in
      --help) arguments "$#" 2 "channel --help" ;;
      list)
        arguments "$#" 4 "channel list <org> <peer>"
        identifier "org" "$3"
        identifier "peer" "$4"
        ;;
      getinfo)
        arguments "$#" 5 "channel getinfo <channel> <org> <peer>"
        identifier "channel" "$3"
        identifier "org" "$4"
        identifier "peer" "$5"
        ;;
      fetch)
        arguments "$#" 7 "channel fetch <block> <channel> <org> <peer> <file>"
        [[ "$3" =~ ^(config|newest|oldest|[0-9]+)$ ]] || fail "The block must be config, newest, oldest, or a block number."
        identifier "channel" "$4"
        identifier "org" "$5"
        identifier "peer" "$6"
        optional_path "file" "$7"
        ;;
      *) fail "Unsupported channel command." ;;
    esac
    ;;
  namespace)
    case "${2:-}" in
      list) arguments "$#" 2 "namespace list" ;;
      init)
        arguments "$#" 3 "namespace init <name>"
        [ -z "$3" ] || identifier "namespace" "$3"
        ;;
      *) fail "Expected namespace list or namespace init." ;;
    esac
    ;;
  use)
    arguments "$#" 2 "use <version>"
    [ -z "$2" ] || identifier "version" "$2"
    ;;
  version)
    arguments "$#" 2 "version <verbose>"
    case "$2" in
      "" | false) command=(version) ;;
      true) command=(version --verbose) ;;
      *) fail "verbose must be true or false." ;;
    esac
    ;;
  *) fail "Unsupported MCP command." ;;
esac

# Drop empty trailing arguments, so Fablo applies its own defaults.
while [ "${#command[@]}" -gt 1 ] && [ -z "${command[${#command[@]}-1]}" ]; do
  unset 'command[${#command[@]}-1]'
done

case "$1" in
  info)
    echo "Network directory: $PWD"
    if [ -f fablo-config.json ] && [ -f fablo-config.yaml ]; then
      echo "Config: fablo-config.json (Fablo ignores fablo-config.yaml while both exist)"
    elif [ -f fablo-config.json ] || [ -f fablo-config.yaml ]; then
      echo "Config: $(ls fablo-config.json fablo-config.yaml 2>/dev/null)"
    else
      echo "Config: none. Create one with config_init, or write fablo-config.json in the network directory."
    fi
    if [ -d fablo-target ]; then
      echo "Generated network: fablo-target exists. Changing the config needs network_prune or network_recreate."
    else
      echo "Generated network: none. network_up generates it from the config."
    fi
    exit 0
    ;;
  # The skill and the schema ship with the server, so they match its version.
  skill) exec cat "${FABLO_MCP_DIR:?Start this server with mcp/start.sh}/../skills/fablo/SKILL.md" ;;
  schema) exec cat "${FABLO_MCP_DIR:?Start this server with mcp/start.sh}/../docs/schema.json" ;;
  help | version) fablo "${command[@]}"; exit ;;
esac

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
    ;;
  up | recreate)
    fablo validate "$2"
    reject_config_hooks "$2"
    [ "$1" = recreate ] || reject_rendered_hooks
    ;;
  generate) reject_config_hooks "$2" ;;
  start) reject_rendered_hooks ;;
esac
fablo "${command[@]}"
