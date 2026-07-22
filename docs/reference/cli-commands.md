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
6. Other Implemented Commands (undocumented in source)


# Fablo CLI Command Reference

This reference documents the commands exposed by the Fablo CLI (`fablo`). For each command it lists the command's purpose, its syntax, and the arguments it accepts.

## Network Lifecycle Commands

### `fablo init`

**Purpose:** Creates a simple Fablo config in the current directory, with optional Node.js, chaincode, REST API, and dev mode support.

**Syntax:**
```
fablo init [node] [rest] [dev] [gateway]
```

**Arguments:**
| Argument | Required | Description |
|---|---|---|
| `node` | No | Optional flag enabling Node.js support in the generated config. |
| `rest` | No | Optional flag enabling REST API support in the generated config. |
| `dev` | No | Optional flag enabling dev mode in the generated config. |
| `gateway` | No | Optional flag included in the generated config. |


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

**Purpose:** Starts the Hyperledger Fabric network for the given Fablo configuration file, creating channels and installing and instantiating chaincodes. If no configuration exists yet, it calls the `generate` command for the given config file first.

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
fablo chaincode invoke <channel_name> <chaincode_name> <peers_domains_comma_separated> <command> <transient>
```

**Arguments:**
| Argument | Required | Description |
|---|---|---|
| `channel_name` | Yes | Name of the channel to invoke on. |
| `chaincode_name` | Yes | Name of the chaincode to invoke. |
| `peers_domains_comma_separated` | Yes | Comma-separated list of peer domains to target. |
| `command` | Yes | Invoke command to execute. |
| `transient` | Yes | Transient data for the invocation. |


### `fablo chaincodes list`

**Purpose:** Lists chaincodes installed on a specified peer and channel.

**Syntax:**
```
fablo chaincodes list <peer> <channel>
```

**Arguments:**
| Argument | Required | Description |
|---|---|---|
| `peer` | Yes | Peer to list installed chaincodes for. |
| `channel` | Yes | Channel to list installed chaincodes for. |


### `fablo chaincode query`

**Purpose:** Queries a chaincode with the specified parameters.

**Syntax:**
```
fablo chaincode query <channel_name> <chaincode_name> <peers_domains_comma_separated> <command> <transient>
```

**Arguments:**
| Argument | Required | Description |
|---|---|---|
| `channel_name` | Yes | Name of the channel to query on. |
| `chaincode_name` | Yes | Name of the chaincode to query. |
| `peers_domains_comma_separated` | Yes | Comma-separated list of peer domains to target. |
| `command` | Yes | Query command to execute. |
| `transient` | Yes | Transient data for the query. |


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


## Other Implemented Commands

The following commands are implemented under `src/commands/` but the provided source material does not include usage text, purpose, syntax, or argument details for them:

- `export-network-topology`
- `extend-config`
- `setup-network`
- `validate`
- `version`
