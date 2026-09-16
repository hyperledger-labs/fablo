---
layout: doc
title: CLI commands
---


# Fablo CLI Command Reference

This reference documents the commands exposed by the Fablo CLI (`fablo`). For each command it lists the command's purpose, its syntax, and the arguments it accepts.

**Outline**
1. [Introduction](#fablo-cli-command-reference)
2. [Network Lifecycle Commands](#network-lifecycle-commands) — `init`, `generate`, `up`, `down` / `start` / `stop`, `reset`, `prune`, `recreate`
3. [Chaincode Commands](#chaincode-commands) — `chaincodes install`, `chaincode install`, `chaincode upgrade`, `chaincode dev`, `chaincode invoke`, `chaincodes list`, `chaincode query`
4. [Channel Commands](#channel-commands) — `channel --help`, `channel list`, `channel getinfo`, `channel fetch`
5. [Snapshot Commands](#snapshot-commands) — `snapshot`, `restore`
6. [Utility Commands](#utility-commands) — `validate`, `version`, `export-network-topology`, `extend-config`, `use`, `help`


## Network Lifecycle Commands

### `fablo init`

**Purpose:** Creates a simple Fablo config in the current directory, with optional Node.js chaincode, CCaaS sample, REST API, gateway sample, and dev mode support. It can also create a minimal config for the experimental Fabric-X provider.

**Syntax:**
```
fablo init [node] [rest] [dev] [ccaas] [gateway] [--set <path>=<value> ...]
fablo init fabric-x [--set <path>=<value> ...]
```

Option order does not matter. The valid options are `node`, `dev`, `ccaas`, `gateway`, `rest` and `fabric-x`.

**Arguments:**

| Argument | Required | Description |
|---|---|---|
| `node` | No | Copies a sample Node.js chaincode into `chaincodes/chaincode-kv-node` and registers it in the config. |
| `rest` | No | Enables Fablo REST for each organization in the generated config. |
| `dev` | No | Used together with `node`. The sample chaincode is registered as a chaincode as a service that reloads when you change its source. |
| `ccaas` | No | Adds a sample chaincode-as-a-service definition to the config. Cannot be combined with `node` or `dev`. |
| `gateway` | No | Copies a sample Node.js gateway app into `gateway/node` (does not change the config file itself). |
| `fabric-x` | No | Creates a minimal config for the experimental Fabric-X provider. Cannot be combined with `node`, `dev`, `ccaas`, `gateway` or `rest`. |
| <code>--set &lt;path&gt;=&lt;value&gt;</code> | No | Override one or more fields in the generated config (repeatable). Paths use dotted/`[]` notation, e.g. `orgs[1].peer.db=CouchDb`. |

`fablo init` writes the config to `fablo-config.json` in the current directory. By default the config uses Fabric `3.1.0`, TLS enabled, two BFT orderers, two `LevelDb` peers under `Org1`, and a single channel named `my-channel1`.


### `fablo generate`

**Purpose:** Generates network configuration files in the given directory. If no configuration file is given, it defaults to `$(pwd)/fablo-config.json` or `$(pwd)/fablo-config.yaml`. If no target directory is given, it defaults to (and it is recommended to use) `$(pwd)/fablo-target`.

**Syntax:**
```
fablo generate [/path/to/fablo-config.json|yaml [/path/to/fablo/target]]
```

**Arguments:**

| Argument | Required | Description |
|---|---|---|
| `/path/to/fablo-config.json\|yaml` | No | Path to the Fablo configuration file. Defaults to `$(pwd)/fablo-config.json` or `$(pwd)/fablo-config.yaml`. |
| `/path/to/fablo/target` | No | Directory to generate network configuration files into. Defaults to (and recommended to be) `$(pwd)/fablo-target`. |


### `fablo up`

**Purpose:** Starts the Hyperledger Fabric network for the given Fablo configuration file, creates channels, and installs and deploys chaincodes (package / install / approve / commit). A source `fablo-config.json` or `fablo-config.yaml` must already exist. If the generated `fablo-target` network files are missing, `fablo up` runs `generate` for that config first.

**Syntax:**
```
fablo up [/path/to/fablo-config.json|yaml]
```

**Arguments:**

| Argument | Required | Description |
|---|---|---|
| `/path/to/fablo-config.json\|yaml` | No | Path to the Fablo configuration file. Defaults to `$(pwd)/fablo-config.json` or `$(pwd)/fablo-config.yaml`. |

When `fablo-target` already exists, Fablo compares your configuration file with the copy it stored there when the network was generated. If the two differ, the command stops with an error and prints the difference, so you have to run `fablo prune` or `fablo recreate` before the new configuration takes effect.


### `fablo down` / `fablo start` / `fablo stop`

**Purpose:** Downs, starts, or stops the Hyperledger Fabric network for the configuration in the current directory. This behaves similarly to the `down`, `start`, and `stop` commands for Docker Compose.

**Syntax:**
```
fablo down
fablo start
fablo stop
```

**Arguments:** None.


### `fablo reset`

**Purpose:** Downs and ups the network. Network state is lost, but the configuration is kept intact.

**Syntax:**
```
fablo reset
```

**Arguments:** None.


### `fablo prune`

**Purpose:** Downs the network and removes all generated files.

**Syntax:**
```
fablo prune
```

**Arguments:** None.


### `fablo recreate`

**Purpose:** Prunes and ups the network.

**Syntax:**
```
fablo recreate [/path/to/fablo-config.json|yaml]
```

**Arguments:**

| Argument | Required | Description |
|---|---|---|
| `/path/to/fablo-config.json\|yaml` | No | Path to the Fablo configuration file. Defaults to `$(pwd)/fablo-config.json` or `$(pwd)/fablo-config.yaml`. |


## Chaincode Commands

### `fablo chaincodes install`

**Purpose:** Installs all chaincodes on relevant peers. The chaincode directory is specified in the Fablo config file.

**Syntax:**
```
fablo chaincodes install
```

**Arguments:** None.


### `fablo chaincode install`

**Purpose:** Installs a chaincode on all relevant peers. The chaincode directory is specified in the Fablo config file.

**Syntax:**
```
fablo chaincode install <chaincode-name> <version>
```

**Arguments:**

| Argument | Required | Description |
|---|---|---|
| `chaincode-name` | Yes | Name of the chaincode to install. |
| `version` | Yes | Version of the chaincode to install. |


### `fablo chaincode upgrade`

**Purpose:** Upgrades a chaincode on all relevant peers.

**Syntax:**
```
fablo chaincode upgrade <chaincode-name> <version>
```

**Arguments:**

| Argument | Required | Description |
|---|---|---|
| `chaincode-name` | Yes | Name of the chaincode to upgrade. |
| `version` | Yes | Version to upgrade the chaincode to. |


### `fablo chaincode dev`

**Purpose:** Approves and commits a chaincode definition for peers running in dev mode, using the version from the Fablo config file. Fablo supports dev mode only on channels with Fabric v2 capabilities.

**Syntax:**
```
fablo chaincode dev <chaincode-name>
```

**Arguments:**

| Argument | Required | Description |
|---|---|---|
| `chaincode-name` | Yes | Name of the chaincode to run in dev mode. |


### `fablo chaincode invoke`

**Purpose:** Invokes a chaincode with the specified parameters.

**Syntax:**
```
fablo chaincode invoke <peer_domains_comma_separated> <channel_name> <chaincode_name> <command> [transient]
```

**Arguments:**

| Argument | Required | Description |
|---|---|---|
| `peer_domains_comma_separated` | Yes | Comma-separated list of peer domains to target. |
| `channel_name` | Yes | Name of the channel to invoke on. |
| `chaincode_name` | Yes | Name of the chaincode to invoke. |
| `command` | Yes | Invoke command to execute. |
| `transient` | No | Optional transient data for the invocation. |


### `fablo chaincodes list`

**Purpose:** Lists chaincodes installed on a specified peer and channel.

**Syntax:**
```
fablo chaincodes list <peer_domain> <channel_name>
```

**Arguments:**

| Argument | Required | Description |
|---|---|---|
| `peer_domain` | Yes | Peer to list installed chaincodes for (requires the full domain, like `peer0.org1.example.com`). |
| `channel_name` | Yes | Channel to list installed chaincodes for. |


### `fablo chaincode query`

**Purpose:** Queries a chaincode on a single peer.

**Syntax:**
```
fablo chaincode query <peer_domain> <channel_name> <chaincode_name> <command> [transient]
```

**Arguments:**

| Argument | Required | Description |
|---|---|---|
| `peer_domain` | Yes | Single peer domain to query. |
| `channel_name` | Yes | Name of the channel to query on. |
| `chaincode_name` | Yes | Name of the chaincode to query. |
| `command` | Yes | Query command to execute. |
| `transient` | No | Optional transient data for the query. |


## Channel Commands

Fablo generates the channel commands from the organizations, peers and channels in your config file, so you can only use the names that your own config defines. Write the organization name in lowercase, such as `org1`, and give the peer by its short name, such as `peer0`.

### `fablo channel --help`

**Purpose:** Lists the channel commands available for the generated network, with the organization and peer names it accepts.

**Syntax:**
```
fablo channel --help
```

**Arguments:** None.


### `fablo channel list`

**Purpose:** Lists the channels that a peer has joined.

**Syntax:**
```
fablo channel list <org> <peer>
```

**Arguments:**

| Argument | Required | Description |
|---|---|---|
| `org` | Yes | Lowercase organization name, for example `org1`. |
| `peer` | Yes | Short peer name, for example `peer0`. |


### `fablo channel getinfo`

**Purpose:** Prints information about a channel, as seen by the given peer.

**Syntax:**
```
fablo channel getinfo <channel> <org> <peer>
```

**Arguments:**

| Argument | Required | Description |
|---|---|---|
| `channel` | Yes | Name of the channel. |
| `org` | Yes | Lowercase organization name, for example `org1`. |
| `peer` | Yes | Short peer name, for example `peer0`. |


### `fablo channel fetch config`

**Purpose:** Downloads the latest config block of a channel and saves it as a JSON file.

**Syntax:**
```
fablo channel fetch config <channel> <org> <peer> [file-name.json]
```

**Arguments:**

| Argument | Required | Description |
|---|---|---|
| `channel` | Yes | Name of the channel. |
| `org` | Yes | Lowercase organization name, for example `org1`. |
| `peer` | Yes | Short peer name, for example `peer0`. |
| `file-name.json` | No | Name of the file to write the config block to. |


### `fablo channel fetch`

**Purpose:** Downloads a single block of a channel and saves it to a file.

**Syntax:**
```
fablo channel fetch <newest|oldest|block-number> <channel> <org> <peer> [file-name]
```

**Arguments:**

| Argument | Required | Description |
|---|---|---|
| `newest` \| `oldest` \| `block-number` | Yes | Which block to fetch. |
| `channel` | Yes | Name of the channel. |
| `org` | Yes | Lowercase organization name, for example `org1`. |
| `peer` | Yes | Short peer name, for example `peer0`. |
| `file-name` | No | Name of the file to write the block to. Defaults to `<newest\|oldest\|block-number>.block`. |


## Snapshot Commands

### `fablo snapshot`

**Purpose:** Creates a snapshot of the network at the target path. The snapshot contains all network state, including transactions and identities. Fablo saves it as `<target-snapshot-path>.fablo.tar.gz`, unless the path you give already ends with `tar.gz`, and it stops with an error when that file already exists.

**Syntax:**
```
fablo snapshot <target-snapshot-path>
```

**Arguments:**

| Argument | Required | Description |
|---|---|---|
| `target-snapshot-path` | Yes | Path where the snapshot will be created. |


### `fablo restore`

**Purpose:** Restores the network from a snapshot, so that you can then run it with the `start` command. The current network has to be pruned first, because the command fails when a `fablo-target` directory already exists.

**Syntax:**
```
fablo restore <source-snapshot-path> [hook-command]
```

**Arguments:**

| Argument | Required | Description |
|---|---|---|
| `source-snapshot-path` | Yes | Path to the snapshot to restore from. As with `snapshot`, Fablo appends `.fablo.tar.gz` unless the path already ends with `tar.gz`. |
| `hook-command` | No | Shell command to run in the restored directory before the containers are created. |


## Utility Commands

### `fablo validate`

**Purpose:** Validates a Fablo configuration file, both against the schema and with extra checks across fields. It is a separate command, so `generate` and `up` do not run it for you.

**Syntax:**
```
fablo validate [/path/to/fablo-config.json|yaml]
```

**Arguments:**

| Argument | Required | Description |
|---|---|---|
| `/path/to/fablo-config.json\|yaml` | No | Path to the Fablo configuration file. Defaults to `$(pwd)/fablo-config.json` or `$(pwd)/fablo-config.yaml`. |


### `fablo version`

**Purpose:** Prints the Fablo version and build information as JSON. With `--verbose`, it also prints the range of Fablo config versions this release supports.

**Syntax:**
```
fablo version [--verbose | -v]
```

**Arguments:**

| Argument | Required | Description |
|---|---|---|
| `-v` / `--verbose` | No | Show verbose version information. |


### `fablo export-network-topology`

**Purpose:** Exports the network topology described by a Fablo config to a Mermaid diagram file.

**Syntax:**
```
fablo export-network-topology [/path/to/fablo-config.json|yaml [outputFile.mmd]]
```

**Arguments:**

| Argument | Required | Description |
|---|---|---|
| `/path/to/fablo-config.json\|yaml` | No | Path to the Fablo configuration file. Defaults to `$(pwd)/fablo-config.json` or `$(pwd)/fablo-config.yaml`. |
| `outputFile.mmd` | No | Output Mermaid file path. Defaults to `network-topology.mmd`. |


### `fablo extend-config`

**Purpose:** Reads a Fablo config, applies Fablo's internal config extension, and prints the extended result as JSON (useful for debugging).

**Syntax:**
```
fablo extend-config [/path/to/fablo-config.json|yaml]
```

**Arguments:**

| Argument | Required | Description |
|---|---|---|
| `/path/to/fablo-config.json\|yaml` | No | Path to the Fablo configuration file. Defaults to `$(pwd)/fablo-config.json` or `$(pwd)/fablo-config.yaml`. |


### `fablo use`

**Purpose:** Updates the Fablo script you ran to the given version. With no version, it prints the versions you can choose from.

**Syntax:**
```
fablo use [version]
```

**Arguments:**

| Argument | Required | Description |
|---|---|---|
| `version` | No | Version to update the script to, for example `2.6.0`. Without it, Fablo prints the available versions. |


### `fablo help`

**Purpose:** Prints the manual, with a short description of each command. Running `fablo` with no command prints the same manual and exits with a non-zero status.

**Syntax:**
```
fablo help
fablo --help
```

**Arguments:** None.
