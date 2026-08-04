---
layout: doc
title: CLI commands
---


# Outline

1. Introduction
2. Network Lifecycle Commands — `init`, `generate`, `up`, `down` / `start` / `stop`, `reset`, `prune`, `recreate`
3. Chaincode Commands — `chaincodes install`, `chaincode install`, `chaincode upgrade`, `chaincode invoke`, `chaincodes list`, `chaincode query`
4. Channel Commands — `channel --help`
5. Snapshot Commands — `snapshot`, `restore`
6. Utility Commands — `validate`, `version`, `export-network-topology`, `extend-config`


# Fablo CLI Command Reference

This reference documents the commands exposed by the Fablo CLI (`fablo`). For each command it lists the command's purpose, its syntax, and the arguments it accepts.

## Network Lifecycle Commands

### `fablo init`

**Purpose:** Creates a simple Fablo config in the current directory, with optional Node.js chaincode, CCaaS sample, REST API, gateway sample, and/or dev mode support.

**Syntax:**
```
fablo init [node] [rest] [dev] [ccaas] [gateway] [--set <path>=<value> ...]
```

Option order does not matter. Valid options: `node`, `dev`, `ccaas`, `gateway`, `rest`.

**Arguments:**
| Argument | Required | Description |
|---|---|---|
| `node` | No | Copies a sample Node.js chaincode into `chaincodes/chaincode-kv-node` and registers it in the config. |
| `rest` | No | Enables Fablo REST for each organization in the generated config. |
| `dev` | No | Used with `node`: configures the chaincode for hot-reload / CCaaS-style dev mode. |
| `ccaas` | No | Adds a sample chaincode-as-a-service definition to the config. Cannot be combined with `node` or `dev`. |
| `gateway` | No | Copies a sample Node.js gateway app into a `gateway` directory (does not change the config file itself). |
| `--set <path>=<value>` | No | Override one or more fields in the generated config (repeatable). Paths use dotted/`[]` notation, e.g. `orgs[1].peer.db=CouchDb`. |

By default, `fablo init` writes a config with Fabric `3.1.0`, TLS enabled, two BFT orderers, and two LevelDB peers under `Org1`.


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
| `/path/to/fablo-config.json\|yaml` | No | Path to the Fablo configuration file. |


### `fablo down` / `fablo start` / `fablo stop`

**Purpose:** Downs, starts, or stops the Hyperledger Fabric network for the configuration in the current directory. This behaves similarly to the `down`, `start`, and `stop` commands for Docker Compose.

**Syntax:**
```
fablo down
fablo start
fablo stop
```

**Arguments:**
| Argument | Required | Description |
|---|---|---|
| `down` \| `start` \| `stop` | Yes | Selects which lifecycle action to perform on the network. |


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


### `fablo chaincode invoke`

**Purpose:** Invokes a chaincode with the specified parameters.

**Syntax:**
```
fablo chaincode invoke <peers_domains_comma_separated> <channel_name> <chaincode_name> <command> [transient]
```

**Arguments:**
| Argument | Required | Description |
|---|---|---|
| `peers_domains_comma_separated` | Yes | Comma-separated list of peer domains to target. |
| `channel_name` | Yes | Name of the channel to invoke on. |
| `chaincode_name` | Yes | Name of the chaincode to invoke. |
| `command` | Yes | Invoke command to execute. |
| `transient` | No | Optional transient data for the invocation. |


### `fablo chaincodes list`

**Purpose:** Lists chaincodes installed on a specified peer and channel.

**Syntax:**
```
fablo chaincodes list <peer> <channel>
```

**Arguments:**
| Argument | Required | Description |
|---|---|---|
| `peer` | Yes | Peer to list installed chaincodes for (requires full address, like `peer0.org1.example.com`). |
| `channel` | Yes | Channel to list installed chaincodes for. |


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

### `fablo channel --help`

**Purpose:** Lists available channel query options that can be executed on a running network.

**Syntax:**
```
fablo channel --help
```

**Arguments:** None.


## Snapshot Commands

### `fablo snapshot`

**Purpose:** Creates a snapshot of the network at the target path. The snapshot contains all network state, including transactions and identities.

**Syntax:**
```
fablo snapshot <target-snapshot-path>
```

**Arguments:**
| Argument | Required | Description |
|---|---|---|
| `target-snapshot-path` | Yes | Path where the snapshot will be created. |


### `fablo restore`

**Purpose:** Restores the network from a snapshot.

**Syntax:**
```
fablo restore <source-snapshot-path>
```

**Arguments:**
| Argument | Required | Description |
|---|---|---|
| `source-snapshot-path` | Yes | Path to the snapshot to restore from. |


## Utility Commands

### `fablo validate`

**Purpose:** Validates a Fablo configuration file (schema and cross-field checks). Also runs automatically before `generate`.

**Syntax:**
```
fablo validate [/path/to/fablo-config.json|yaml]
```

**Arguments:**
| Argument | Required | Description |
|---|---|---|
| `/path/to/fablo-config.json\|yaml` | No | Path to the Fablo configuration file. Defaults to `fablo-config.json`. |


### `fablo version`

**Purpose:** Prints Fablo version information.

**Syntax:**
```
fablo version [-v]
```

**Arguments:**
| Argument | Required | Description |
|---|---|---|
| `-v` / `--verbose` | No | Show verbose version information. |


### `fablo export-network-topology`

**Purpose:** Exports the network topology described by a Fablo config to a Mermaid diagram file.

**Syntax:**
```
fablo export-network-topology [/path/to/fablo-config.json] [outputFile.mmd]
```

**Arguments:**
| Argument | Required | Description |
|---|---|---|
| `/path/to/fablo-config.json` | No | Path to the Fablo configuration file. Defaults to `fablo-config.json`. |
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
| `/path/to/fablo-config.json\|yaml` | No | Path to the Fablo configuration file. Defaults to `fablo-config.json`. |
