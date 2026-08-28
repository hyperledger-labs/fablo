---
layout: doc
title: Configuration file
---


# Fablo Configuration File Reference

## Table of Contents

1. [Overview](#overview)
2. [`$schema`](#schema) — schema URL for the config
3. [`global`](#global) — network-wide settings (Fabric version, TLS, engine, provider, images, monitoring, tools)
4. [`orgs`](#orgs) — organization definitions (CA, orderers, peers, tools)
5. [`channels`](#channels) — channel definitions and organization/peer membership
6. [`chaincodes`](#chaincodes) — chaincode definitions, endorsement, and private data collections
7. [`hooks`](#hooks) — commands run after generate / start


## Overview

A Fablo configuration file is a **JSON or YAML** document. Required top-level sections: `global`, `orgs`, `channels`, and `chaincodes`. Optional top-level fields: `$schema` and `hooks`.

Commands that take an optional config path, such as `fablo up` and `fablo validate`, look for `fablo-config.json` in the current directory, and fall back to `fablo-config.yaml` if the JSON file is not there.

This page covers the main fields used in practice. For the full JSON Schema (including schema-only defaults), see [`schema.json`](/schema.json). Note that some schema defaults (for example Fabric `2.4.2` or a solo orderer) are stale relative to what `fablo init` generates today, so prefer the `fablo init` defaults below when starting a new network.

**What `fablo init` generates today:** Fabric `3.1.0`, TLS on, engine `docker`, an `Orderer` organization with two BFT orderers in group `group1`, an `Org1` organization with two LevelDB peers, channel `my-channel1`, and empty `chaincodes` and `hooks`. The generated channel has no `ordererGroup`, so it falls back to the first orderer group. `fablo init fabric-x` writes a different starter config, described under [`global.provider`](#globalprovider).


## `$schema`

| Field | Purpose | Type | Required |
|---|---|---|---|
| `$schema` | URL of the Fablo JSON Schema used to validate this config | `string` | Recommended |

`fablo init` sets this to the schema for the Fablo release you are running, for example:

```json
"$schema": "https://github.com/hyperledger-labs/fablo/releases/download/<version>/schema.json"
```

`fablo validate` reads the version out of the URL and reports an error when it does not match the Fablo release you are running, so update `$schema` when you upgrade Fablo.


## `global`

Basic settings of the Hyperledger Fabric network. Type: `object`. Required fields: `fabricVersion`, `tls`.

| Field | Purpose | Type | Required | Notes |
|---|---|---|---|---|
| `fabricVersion` | Hyperledger Fabric version to use for the network | `string` | Yes | Must be `2.0.0` or higher. `fablo init` uses `3.1.0` |
| `tls` | Whether TLS is used across the network | `boolean` | Yes | `fablo init` uses `true` |
| `peerDevMode` | Start all peers in dev mode | `boolean` | No | Default `false`. Requires `tls` to be `false`, and `fablo validate` reports an error when both are `true`. Supported on Fabric v2 only, not on Fabric v3. See [SUPPORTED_FEATURES.md](https://github.com/hyperledger-labs/fablo/blob/main/SUPPORTED_FEATURES.md). |
| `engine` | Engine on which the network will be deployed | `string` | No | `docker` (default) or `kubernetes` |
| `provider` | Network provider | `string` | No | `fabric` (default) or `fabric-x`. `fabric-x` is experimental, see below |
| `fabricImages` | Optional Docker images for Hyperledger Fabric components | `object` | No | see below |
| `monitoring` | Optional settings for monitoring purposes | `object` | No | see below |
| `tools` | Tool toggles at the network level | `object` | No | see below |

### `global.provider`

Selects the network provider. The default is `fabric`, which is the fully supported Hyperledger Fabric network. The value `fabric-x` selects the experimental Fabric-X provider, and `fablo init fabric-x` writes a starter config that uses it.

When `provider` is `fabric-x`, `fablo validate` reports an error for any of the following:

- `engine` is `kubernetes`, because Fabric-X supports `docker` only
- `tls` is `false`, because Fabric-X requires TLS
- `peerDevMode` is `true`
- Explorer or Fablo REST is enabled, in `global.tools` or in any `orgs[].tools`
- `chaincodes` is not empty, because the Fabric-X provider does not deploy chaincodes yet
- `channels` does not hold exactly one channel

### `global.fabricImages`

Optional Docker images for Hyperledger Fabric components.

| Field | Purpose | Type | Required | Default |
|---|---|---|---|---|
| `peer` | Peer image | `string` | No | `hyperledger/fabric-peer` |
| `orderer` | Orderer image | `string` | No | `hyperledger/fabric-orderer` |
| `ca` | CA image | `string` | No | `hyperledger/fabric-ca` |
| `tools` | Tools image | `string` | No | `hyperledger/fabric-tools` below Fabric `3.0.0`, `ghcr.io/fablo-io/fabric-tools` from Fabric `3.0.0` up |
| `ccenv` | CCENV image | `string` | No | `hyperledger/fabric-ccenv` |
| `baseos` | BaseOS image | `string` | No | `hyperledger/fabric-baseos` |
| `javaenv` | Javaenv image | `string` | No | `hyperledger/fabric-javaenv` |
| `nodeenv` | Nodeenv image | `string` | No | `hyperledger/fabric-nodeenv` |

The defaults above are repository names without a tag. When you give an image with no tag and no digest, Fablo appends a tag it derives from `fabricVersion`, so `myregistry/fabric-peer` becomes `myregistry/fabric-peer:3.1.0` on a Fabric `3.1.0` network. Give the image with a tag or a digest to pin it yourself.

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

When `global.tools.explorer` is `true`, Fablo runs one Explorer for the whole network and ignores the `orgs[].tools.explorer` setting on each organization. `fablo validate` warns about each organization whose setting is ignored this way.

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

- `solo` is for Fabric v2 development only; it is not supported on Fabric v3. With `solo`, only one instance is created, and `fablo validate` warns if `instances` is greater than `1`.
- `raft` requires `global.tls` to be `true`.
- `BFT` requires Fabric v3.
- An organization may have at most 9 orderers in total across all of its groups.
- `groupName` must be unique within an organization, and every orderer in a group must use the same `type`, even when the group spans several organizations.
- `fablo init` creates one orderer group: `groupName: "group1"`, `type: "BFT"`, `instances: 2`.

### `orgs[].peer`

Peer settings for this organization. If a `peer` object is present, `instances` is required within it. Orderer-only organizations (such as `orgs[0]` from `fablo init`) typically have no `peer` block.

| Field | Purpose | Type | Required | Allowed values |
|---|---|---|---|---|
| `prefix` | Domain prefix | `string` | No | pattern `^[a-z0-9\.\-]+$` (default `peer`) |
| `instances` | Number of peer instances | `integer` | Yes (within `peer`) | minimum `1`, maximum `9` |
| `anchorPeerInstances` | Number of anchor peer instances | `integer` | No | minimum `1`, maximum `9` (defaults to the value of `instances`) |
| `db` | Peer database type | `string` | No | `LevelDb` (default), `CouchDb` |

Peers are named after the `prefix` followed by a zero based index, so the default `prefix` gives `peer0`, `peer1` and so on. The first `anchorPeerInstances` peers become anchor peers, and because the default is the value of `instances`, every peer is an anchor peer unless you set a lower number. `fablo validate` reports an error when `anchorPeerInstances` is greater than `instances`.

### `orgs[].tools`

| Field | Purpose | Type | Required |
|---|---|---|---|
| `fabloRest` | Whether [Fablo REST](https://github.com/fablo-io/fablo-rest) is enabled | `boolean` | No |
| `explorer` | Whether Blockchain Explorer is enabled for this org | `boolean` | No |

Fablo REST is a separate REST API client for CA and chaincodes. It is not the same as the optional Node.js gateway sample copied by `fablo init gateway`. Explorer is Fabric v2 only.

Fablo REST cannot be used together with `global.peerDevMode`, and `fablo validate` reports an error for each organization that enables both. Peers in dev mode do not expose their chaincodes through the discovery service, which Fablo REST needs.

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
| `ordererGroup` | Name of the orderer **group** (`orgs[].orderers[].groupName`) that handles this channel | `string` | No | pattern `^[a-zA-Z0-9]+$` (defaults to the first orderer group defined in `orgs`) |
| `orgs` | Organizations participating in the channel | `array` | Yes | see below |

`ordererGroup` references an orderer group's `groupName`, not an organization name. `fablo validate` reports an error when the value does not match a `groupName` defined in `orgs`. The pattern for `ordererGroup` allows letters and digits only, so it cannot reference a `groupName` that contains a dot or a hyphen.

### `channels[].orgs[]`

Each item requires `name` and `peers`.

| Field | Purpose | Type | Required | Allowed values |
|---|---|---|---|---|
| `name` | Organization name (must match an organization defined in `orgs`) | `string` | Yes | pattern `^[a-zA-Z0-9]+$` |
| `peers` | Peers for the organization on this channel | `array` of `string` | Yes | each item pattern `^[a-z0-9]+$` |

Each entry in `peers` is a peer name, which is the organization's peer `prefix` followed by a zero based index, for example `peer0`. An organization listed here must have a `peer` block, so you cannot join an orderer-only organization to a channel.

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
| `init` | Initialization arguments | `string` | No | default `{"Args":[]}` |
| `initRequired` | Whether the chaincode requires an initialization transaction | `boolean` | No | default `false` |
| `endorsement` | Endorsement policy | `string` | No | see below |
| `directory` | Chaincode source directory | `string` | Required unless `lang` is `ccaas` | — |
| `image` | Chaincode image URI | `string` | Required only when `lang` is `ccaas` | — |
| `chaincodeMountPath` | Directory mounted into the chaincode container as its working directory | `string` | No | **`ccaas` only** |
| `chaincodeStartCommand` | Command used as the chaincode container command | `string` | No | **`ccaas` only** |
| `privateData` | Private data collections | `array` | No | see below |

Fablo chooses between `init` and `initRequired` from `global.fabricVersion`. On Fabric 2.x it uses `initRequired`, and `fablo validate` warns that `init` is ignored. From Fabric `3.0.0` up it uses `init`, and `fablo validate` warns that `initRequired` is ignored.

When you leave `endorsement` out, the default depends on `global.fabricVersion` as well. On Fabric 2.x Fablo sets no policy and Fabric applies its own default. From Fabric `3.0.0` up Fablo builds a policy that requires every organization on the channel, for example `AND ('Org1MSP.member')` for a channel with only `Org1`.

Constraints:

- `chaincodeMountPath` and `chaincodeStartCommand` are only valid when `lang` is `ccaas`. Using them with `node` / `golang` / `java` fails validation.
- `lang: "ccaas"` requires `global.tls` to be `true`. CCaaS without TLS is not supported yet.
- Chaincode names must be unique within a channel.
- `fablo init ccaas` cannot be combined with `node` or `dev`.
- Peer dev mode (`global.peerDevMode` / `fablo init node dev`) has Fabric-version limits; see [SUPPORTED_FEATURES.md](https://github.com/hyperledger-labs/fablo/blob/main/SUPPORTED_FEATURES.md).

### `chaincodes[].privateData[]`

Each item requires `name` and `orgNames`.

| Field | Purpose | Type | Required | Allowed values |
|---|---|---|---|---|
| `name` | Private data collection name | `string` | Yes | pattern `^[A-Za-z0-9_-]+$` |
| `orgNames` | Organizations included in the collection | `array` of `string` | Yes | each item pattern `^[A-Za-z0-9]+$` |

Every name in `orgNames` must be an organization that has joined the chaincode's channel, not merely an organization defined in `orgs`. Fablo builds the collection policy as `OR` over the MSPs of the named organizations, for example `OR('Org1MSP.member')`.

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

Fablo renders each hook into a script under `fablo-target/hooks/` and runs it from the directory where you ran `fablo`, not from `fablo-target`. A relative path in a hook is resolved against your project directory, which is why the example below can use `./chaincodes/chaincode-kv-node`.

### Example

```json
"hooks": {
  "postGenerate": "npm i --prefix ./chaincodes/chaincode-kv-node",
  "postStart": "echo network is up"
}
```
