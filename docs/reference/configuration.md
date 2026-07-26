---
layout: doc
title: Configuration file
---


# Fablo Configuration File Reference

## Table of Contents

1. [Overview](#overview)
2. [`$schema`](#schema) — schema URL for the config
3. [`global`](#global) — network-wide settings (Fabric version, TLS, images, engine, monitoring, tools)
4. [`orgs`](#orgs) — organization definitions (CA, orderers, peers, tools)
5. [`channels`](#channels) — channel definitions and organization/peer membership
6. [`chaincodes`](#chaincodes) — chaincode definitions, endorsement, and private data collections
7. [`hooks`](#hooks) — commands run after generate / start


## Overview

A Fablo configuration file is a **JSON or YAML** document. Required top-level sections: `global`, `orgs`, `channels`, and `chaincodes`. Optional top-level fields: `$schema` and `hooks`.

This page covers the main fields used in practice. For the full JSON Schema (including schema-only defaults), see [`schema.json`](/schema.json). Note that some schema defaults (for example Fabric `2.4.2` or a solo orderer) are stale relative to what `fablo init` generates today — prefer the `fablo init` defaults below when starting a new network.

**What `fablo init` generates today:** Fabric `3.1.0`, TLS on, two BFT orderers, two LevelDB peers under `Org1`, channel `my-channel1`, empty `chaincodes` and `hooks`.


## `$schema`

| Field | Purpose | Type | Required |
|---|---|---|---|
| `$schema` | URL of the Fablo JSON Schema used to validate this config | `string` | Recommended |

`fablo init` sets this to the schema for the current Fablo release, for example:

```json
"$schema": "https://github.com/hyperledger-labs/fablo/releases/download/<version>/schema.json"
```


## `global`

Basic settings of the Hyperledger Fabric network. Type: `object`. Required fields: `fabricVersion`, `tls`.

| Field | Purpose | Type | Required | Notes |
|---|---|---|---|---|
| `fabricVersion` | Hyperledger Fabric version to use for the network | `string` | Yes | `fablo init` uses `3.1.0` |
| `tls` | Whether TLS is used across the network | `boolean` | Yes | `fablo init` uses `true` |
| `peerDevMode` | Start all peers in dev mode | `boolean` | No | Default `false`. Supported on Fabric v2 without TLS; not supported on Fabric v3. See [SUPPORTED_FEATURES.md](https://github.com/hyperledger-labs/fablo/blob/main/SUPPORTED_FEATURES.md). |
| `engine` | Engine on which the network will be deployed | `string` | No | `docker` (default) or `kubernetes` |
| `fabricImages` | Optional Docker images for Hyperledger Fabric components | `object` | No | see below |
| `monitoring` | Optional settings for monitoring purposes | `object` | No | see below |
| `tools` | Tool toggles at the network level | `object` | No | see below |

### `global.fabricImages`

Optional Docker images for Hyperledger Fabric components.

| Field | Purpose | Type | Required | Default |
|---|---|---|---|---|
| `peer` | Peer image | `string` | No | `hyperledger/fabric-peer` |
| `orderer` | Orderer image | `string` | No | `hyperledger/fabric-orderer` |
| `ca` | CA image | `string` | No | `hyperledger/fabric-ca` |
| `tools` | Tools image | `string` | No | `hyperledger/fabric-tools` (Fabric 3.x default repo: `ghcr.io/fablo-io/fabric-tools`) |
| `ccenv` | CCENV image | `string` | No | `hyperledger/fabric-ccenv` |
| `baseos` | BaseOS image | `string` | No | `hyperledger/fabric-baseos` |
| `javaenv` | Javaenv image | `string` | No | `hyperledger/fabric-javaenv` |
| `nodeenv` | Nodeenv image | `string` | No | `hyperledger/fabric-nodeenv` |

### `global.monitoring`

Optional settings for monitoring purposes.

| Field | Purpose | Type | Required | Default | Allowed values |
|---|---|---|---|---|---|
| `loglevel` | Log level for all components | `string` | No | `info` | `debug`, `info`, `warn` |

### `global.tools`

| Field | Purpose | Type | Required | Default |
|---|---|---|---|---|
| `explorer` | Whether Blockchain Explorer is enabled network-wide | `boolean` | No | `false` |

Explorer is supported on Fabric v2 only, not on Fabric v3 (including the default `3.1.0` init config). See [SUPPORTED_FEATURES.md](https://github.com/hyperledger-labs/fablo/blob/main/SUPPORTED_FEATURES.md).

### Example

```json
"global": {
  "fabricVersion": "3.1.0",
  "tls": true,
  "peerDevMode": false
}
```


## `orgs`

An array of organization definitions. Type: `array`. Each item's required field: `organization`.

### `orgs[].organization`

Basic information about the organization. Required fields: `name`, `domain`.

| Field | Purpose | Type | Required | Allowed values / pattern |
|---|---|---|---|---|
| `name` | Organization name | `string` | Yes | pattern `^[a-zA-Z0-9]+$` |
| `mspName` | MSP name | `string` | No | pattern `^[a-zA-Z0-9]+$` (defaults to `name + "MSP"`) |
| `domain` | Organization domain | `string` | Yes | pattern `^[a-z0-9\.\-]+$` |

### `orgs[].ca`

Organization Certificate Authority (CA) settings.

| Field | Purpose | Type | Required | Allowed values |
|---|---|---|---|---|
| `prefix` | Domain prefix | `string` | No | pattern `^[a-z0-9\.\-]+$` (default `ca`) |
| `db` | CA database | `string` | No | `sqlite` (default), `postgres`, `mysql` |

### `orgs[].orderers`

An array of orderer group definitions for this organization. Each item requires `groupName`, `type`, `instances`. Organizations without orderers omit this field or use an empty array.

| Field | Purpose | Type | Required | Allowed values |
|---|---|---|---|---|
| `groupName` | Name of the orderer group | `string` | Yes | pattern `^[a-z0-9\.\-]+$` |
| `prefix` | Domain prefix | `string` | No | pattern `^[a-z0-9\.\-]+$` (default `orderer`) |
| `type` | Orderer consensus type | `string` | Yes | `solo`, `raft`, `BFT` |
| `instances` | Number of orderer instances | `integer` | Yes | minimum `1`, maximum `9` |

Notes:

- `solo` is for Fabric v2 development only; it is not supported on Fabric v3.
- `BFT` requires Fabric v3.
- `fablo init` creates one orderer group: `groupName: "group1"`, `type: "BFT"`, `instances: 2`.

### `orgs[].peer`

Peer settings for this organization. If a `peer` object is present, `instances` is required within it. Orderer-only organizations (such as `orgs[0]` from `fablo init`) typically have no `peer` block.

| Field | Purpose | Type | Required | Allowed values |
|---|---|---|---|---|
| `prefix` | Domain prefix | `string` | No | pattern `^[a-z0-9\.\-]+$` (default `peer`) |
| `instances` | Number of peer instances | `integer` | Yes (within `peer`) | minimum `1`, maximum `9` |
| `anchorPeerInstances` | Number of anchor peer instances | `integer` | No | minimum `1`, maximum `9` |
| `db` | Peer database type | `string` | No | `LevelDb` (default), `CouchDb` |

### `orgs[].tools`

| Field | Purpose | Type | Required |
|---|---|---|---|
| `fabloRest` | Whether [Fablo REST](https://github.com/fablo-io/fablo-rest) is enabled | `boolean` | No |
| `explorer` | Whether Blockchain Explorer is enabled for this org | `boolean` | No |

Fablo REST is a separate REST API client for CA and chaincodes. It is not the same as the optional Node.js gateway sample copied by `fablo init gateway`. Explorer is Fabric v2 only.

### Example

```json
"orgs": [
  {
    "organization": {
      "name": "Orderer",
      "mspName": "OrdererMSP",
      "domain": "orderer.example.com"
    },
    "ca": { "prefix": "ca", "db": "sqlite" },
    "orderers": [
      { "groupName": "group1", "prefix": "orderer", "type": "BFT", "instances": 2 }
    ]
  },
  {
    "organization": {
      "name": "Org1",
      "mspName": "Org1MSP",
      "domain": "org1.example.com"
    },
    "ca": { "prefix": "ca", "db": "sqlite" },
    "orderers": [],
    "peer": { "prefix": "peer", "instances": 2, "db": "LevelDb" }
  }
]
```


## `channels`

An array of channel definitions. Type: `array`. Each item's required fields: `name`, `orgs`.

| Field | Purpose | Type | Required | Allowed values |
|---|---|---|---|---|
| `name` | Channel name | `string` | Yes | pattern `^[a-z0-9_-]+$` |
| `ordererGroup` | Name of the orderer **group** (`orgs[].orderers[].groupName`) that handles this channel | `string` | No | Defaults to the first orderer group found |
| `orgs` | Organizations participating in the channel | `array` | Yes | see below |

`ordererGroup` references an orderer group's `groupName`, not an organization name.

### `channels[].orgs[]`

Each item requires `name` and `peers`.

| Field | Purpose | Type | Required | Allowed values |
|---|---|---|---|---|
| `name` | Organization name (must match an organization defined in `orgs`) | `string` | Yes | pattern `^[a-zA-Z0-9]+$` |
| `peers` | Peers for the organization on this channel | `array` of `string` | Yes | each item pattern `^[a-z0-9]+$` |

### Example

```json
"channels": [
  {
    "name": "my-channel1",
    "ordererGroup": "group1",
    "orgs": [
      { "name": "Org1", "peers": ["peer0", "peer1"] }
    ]
  }
]
```


## `chaincodes`

An array of chaincode definitions. Type: `array`. Each item's required fields: `name`, `version`, `lang`, `channel`. Additionally, if `lang` is `ccaas`, `image` is required; otherwise `directory` is required.

| Field | Purpose | Type | Required | Allowed values |
|---|---|---|---|---|
| `name` | Chaincode name | `string` | Yes | pattern `^[a-zA-Z0-9_-]+$` |
| `version` | Chaincode version | `string` | Yes | pattern `^[a-zA-Z0-9\.]+$` |
| `lang` | Chaincode language | `string` | Yes | `golang`, `java`, `node`, `ccaas` |
| `channel` | Channel name the chaincode is deployed on (must match a channel defined in `channels`) | `string` | Yes | pattern `^[a-z0-9_-]+$` |
| `init` | Initialization arguments (legacy; Fabric below 2.0) | `string` | No | — |
| `initRequired` | Whether the chaincode requires an initialization transaction (Fabric 2.0+) | `boolean` | No | default `false` |
| `endorsement` | Endorsement policy | `string` | No | — |
| `directory` | Chaincode source directory | `string` | Required unless `lang` is `ccaas` | — |
| `image` | Chaincode image URI | `string` | Required only when `lang` is `ccaas` | — |
| `chaincodeMountPath` | Directory mounted into the chaincode container as its working directory | `string` | No | **`ccaas` only** |
| `chaincodeStartCommand` | Command used as the chaincode container command | `string` | No | **`ccaas` only** |
| `privateData` | Private data collections | `array` | No | see below |

Constraints:

- `chaincodeMountPath` and `chaincodeStartCommand` are only valid when `lang` is `ccaas`. Using them with `node` / `golang` / `java` fails validation.
- `fablo init ccaas` cannot be combined with `node` or `dev`.
- Peer dev mode (`global.peerDevMode` / `fablo init node dev`) has Fabric-version limits; see [SUPPORTED_FEATURES.md](https://github.com/hyperledger-labs/fablo/blob/main/SUPPORTED_FEATURES.md).

### `chaincodes[].privateData[]`

Each item requires `name` and `orgNames`.

| Field | Purpose | Type | Required | Allowed values |
|---|---|---|---|---|
| `name` | Private data collection name | `string` | Yes | pattern `^[A-Za-z0-9_-]+$` |
| `orgNames` | Organizations included in the collection (must match organizations defined in `orgs`) | `array` of `string` | Yes | each item pattern `^[A-Za-z0-9]+$` |

### Example

```json
"chaincodes": [
  {
    "name": "chaincode1",
    "version": "0.0.1",
    "lang": "node",
    "channel": "my-channel1",
    "endorsement": "AND ('Org1MSP.member')",
    "directory": "./chaincodes/chaincode-kv-node",
    "privateData": [
      { "name": "privateCollectionOrg1", "orgNames": ["Org1"] }
    ]
  }
]
```

CCaaS example:

```json
{
  "name": "chaincode1",
  "version": "0.0.1",
  "lang": "ccaas",
  "channel": "my-channel1",
  "image": "ghcr.io/fablo-io/fablo-sample-kv-node-chaincode:2.2.0",
  "chaincodeStartCommand": "npm run start:ccaas"
}
```


## `hooks`

Optional Bash commands run after specific events.

| Field | Purpose | Type | Required |
|---|---|---|---|
| `postGenerate` | Run after network config is generated (`fablo generate`, or automatically during `fablo up`) | `string` | No |
| `postStart` | Run after the network is started (`fablo up` or `fablo start`) | `string` | No |

### Example

```json
"hooks": {
  "postGenerate": "npm i --prefix ./chaincodes/chaincode-kv-node",
  "postStart": "echo network is up"
}
```
