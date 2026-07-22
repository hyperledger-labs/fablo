---
layout: doc
title: Configuration file
---


# Fablo Configuration File Reference

## Table of Contents

1. [Overview](#overview)
2. [`global`](#global) — network-wide settings (Fabric version, TLS, images, engine, monitoring, tools)
3. [`orgs`](#orgs) — organization definitions (CA, orderers, peers, tools)
4. [`channels`](#channels) — channel definitions and organization/peer membership
5. [`chaincodes`](#chaincodes) — chaincode definitions, endorsement, and private data collections


## Overview

A Fablo configuration file is a JSON document with four required top-level sections: `global`, `orgs`, `channels`, and `chaincodes`. Each section is documented below field by field, with type, required/optional status, default value, and allowed values.


## `global`

Basic settings of the Hyperledger Fabric network. Type: `object`. Required fields: `fabricVersion`, `tls`.

| Field | Purpose | Type | Required | Default | Allowed values |
|---|---|---|---|---|---|
| `fabricVersion` | Hyperledger Fabric version to use for the network | `string` | Yes | `2.4.2` | — |
| `tls` | Whether TLS is used across the network | `boolean` | Yes | `true` | — |
| `peerDevMode` | Start all peers in dev mode | `boolean` | No | `false` | — |
| `engine` | Engine on which the network will be deployed | `string` | No | `docker` | `docker`, `kubernetes` |
| `fabricImages` | Optional Docker images for Hyperledger Fabric components | `object` | No | — | see below |
| `monitoring` | Optional settings for monitoring purposes | `object` | No | — | see below |
| `tools` | Tool toggles at the network level | `object` | No | — | see below |

### `global.fabricImages`

Optional Docker images for Hyperledger Fabric components.

| Field | Purpose | Type | Required | Default |
|---|---|---|---|---|
| `peer` | Peer image | `string` | No | `hyperledger/fabric-peer` |
| `orderer` | Orderer image | `string` | No | `hyperledger/fabric-orderer` |
| `ca` | CA image | `string` | No | `hyperledger/fabric-ca` |
| `tools` | Tools image | `string` | No | `hyperledger/fabric-tools` |
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
| `explorer` | Whether Blockchain Explorer is enabled | `boolean` | No | — |

### Example

```json
"global": {
  "fabricVersion": "2.3.2",
  "tls": false,
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
| `mspName` | MSP name | `string` | No | pattern `^[a-zA-Z0-9]+$` |
| `domain` | Organization domain | `string` | Yes | pattern `^[a-z0-9\.\-]+$` |

### `orgs[].ca`

Organization Certificate Authority (CA) settings.

| Field | Purpose | Type | Required | Allowed values |
|---|---|---|---|---|
| `prefix` | Domain prefix | `string` | No | pattern `^[a-z0-9\.\-]+$` |
| `db` | CA database | `string` | No | `sqlite`, `postgres`, `mysql` |

### `orgs[].orderers`

An array of orderer group definitions for this organization. Each item requires `groupName`, `type`, `instances`.

| Field | Purpose | Type | Required | Allowed values |
|---|---|---|---|---|
| `groupName` | Name of the orderer group | `string` | Yes | pattern `^[a-z0-9\.\-]+$` |
| `prefix` | Domain prefix | `string` | No | pattern `^[a-z0-9\.\-]+$` |
| `type` | Orderer consensus type. The `solo` type may be used in development environments only; use `raft` in production. | `string` | Yes | `solo`, `raft`, `BFT` |
| `instances` | Number of orderer instances | `integer` | Yes | minimum `1`, maximum `9` |

Default value for `orderers`:

```json
"orderers": [
  {
    "groupName": "group1",
    "prefix": "orderer",
    "type": "solo",
    "instances": 1
  }
]
```

### `orgs[].peer`

Peer settings for this organization. If a `peer` object is present, `instances` is required within it.

| Field | Purpose | Type | Required | Allowed values |
|---|---|---|---|---|
| `prefix` | Domain prefix | `string` | No | pattern `^[a-z0-9\.\-]+$` |
| `instances` | Number of peer instances | `integer` | Yes (within `peer`) | minimum `1`, maximum `9` |
| `anchorPeerInstances` | Number of anchor peer instances | `integer` | No | minimum `1`, maximum `9` |
| `db` | Peer database type | `string` | No | `LevelDb`, `CouchDb` |

### `orgs[].tools`

| Field | Purpose | Type | Required |
|---|---|---|---|
| `fabloRest` | Whether Fablo REST is enabled | `boolean` | No |
| `explorer` | Whether Blockchain Explorer is enabled | `boolean` | No |

### Example

```json
"orgs": [
  {
    "organization": {
      "name": "Orderer",
      "mspName": "OrdererMSP",
      "domain": "root.com"
    },
    "orderers": [
      { "groupName": "group1", "prefix": "orderer", "type": "solo", "instances": 1 }
    ]
  },
  {
    "organization": {
      "name": "Org1",
      "mspName": "Org1MSP",
      "domain": "org1.example.com"
    },
    "ca": { "prefix": "ca" },
    "peer": { "prefix": "peer", "instances": 2, "db": "LevelDb" }
  }
]
```


## `channels`

An array of channel definitions. Type: `array`. Each item's required fields: `name`, `orgs`.

| Field | Purpose | Type | Required | Allowed values |
|---|---|---|---|---|
| `name` | Channel name | `string` | Yes | pattern `^[a-z0-9_-]+$` |
| `ordererGroup` | Name of the orderer org handling the channel | `string` | No | pattern `^[a-zA-Z0-9]+$` |
| `orgs` | Organizations participating in the channel | `array` | Yes | see below |

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
| `init` | Initialization arguments (for Hyperledger Fabric below 2.0) | `string` | No | — |
| `initRequired` | Whether the chaincode requires an initialization transaction (for Hyperledger Fabric 2.0 and greater) | `boolean` | No | — |
| `endorsement` | Endorsement configuration | `string` | No | — |
| `directory` | Chaincode source directory | `string` | Required unless `lang` is `ccaas` | — |
| `image` | Chaincode image URI | `string` | Required only when `lang` is `ccaas` | — |
| `privateData` | Private data collections | `array` | No | see below |

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
    "init": "{\"Args\":[]}",
    "endorsement": "AND ('Org1MSP.member')",
    "directory": "./chaincode1",
    "privateData": [
      { "name": "privateCollectionOrg1", "orgNames": ["Org1"] }
    ]
  }
]
```
