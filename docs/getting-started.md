---
layout: doc
title: Getting started
---


# Set Up Your First Fablo Network

**Outline**
1. [What You'll Need](#what-youll-need)
2. [Step 1 — Scaffold a Config with `fablo init`](#step-1--scaffold-a-config-with-fablo-init)
3. [Step 2 — Generate and Start the Network with `fablo up`](#step-2--generate-and-start-the-network-with-fablo-up)
4. [Step 3 — Tear Down the Network](#step-3--tear-down-the-network) (`down` / `prune`)
5. [Fabric-X Getting Started Workflow](#fabric-x-getting-started-workflow)


## What You'll Need

- Fablo installed and available on your command line.
- A working directory where Fablo can create its configuration and generated network files.

## Step 1 — Scaffold a Config with `fablo init`

Create a starting configuration file in your current directory:

```
fablo init
```

This writes a `fablo-config.json` describing a simple Hyperledger Fabric network:

- Fabric version `3.1.5` with TLS enabled
- an orderer organization with two BFT orderers
- one peer organization (`Org1`) with two LevelDB peers
- a single channel (`my-channel1`)
- no chaincodes

If you want extra scaffolding alongside the config, pass one or more options (order doesn't matter):

```
fablo init node
fablo init node dev
fablo init ccaas
fablo init gateway
fablo init rest
```

- `node` — copies a sample Node.js chaincode into `chaincodes/chaincode-kv-node` and registers it in the config.
- `dev` — used together with `node`, configures the chaincode to run as a chaincode-as-a-service container that reloads on source changes, instead of a normal install.
- `ccaas` — adds a sample chaincode-as-a-service definition to the config. It does not copy any chaincode source, and it cannot be combined with `node` or `dev`.
- `gateway` — copies a sample Node.js gateway app into `gateway/node`, which is separate from Fablo REST.
- `rest` — enables [Fablo REST](https://github.com/fablo-io/fablo-rest) for each organization in the config.

The `fabric-x` option works differently, because you get a whole different starter config instead of extra scaffolding on top of the default one:

```
fablo init fabric-x
```

Fablo writes a starter configuration for the Fabric-X provider, with `global.provider` set to `fabric-x`, a single organization (`Org1`), a channel named `mychannel` that all organizations join, and a namespace named `mynamespace`. The configuration holds only what you need to change, and Fablo derives the rest. The orderer is a single party by default, and `--set fabricX.orderer.partyCount=4` selects the four party BFT profile. You cannot combine `fabric-x` with `node`, `dev`, `ccaas`, `gateway` or `rest`.

You can also override generated fields with `--set`:

```
fablo init --set global.fabricVersion=2.5.16
fablo init --set global.monitoring.loglevel=debug --set orgs[1].peer.db=CouchDb
fablo init node --set orgs[1].peer.instances=5
```

Use `orgs[1]` for peer settings, because `orgs[0]` is the orderer organization and has no `peer` block. If you add a `peer` block where there was none, for example with `--set orgs[0].peer.db=CouchDb`, Fablo rejects the result, because a `peer` block also needs `instances`. Every override is checked against the schema before anything is saved, so a config file is written only when the final config is valid.

## Step 2 — Generate and Start the Network with `fablo up`

Start the network defined by your config:

```
fablo up
```

By default this looks for `fablo-config.json` or `fablo-config.yaml` in the current directory, and you can point it at another file with `fablo up [/path/to/fablo-config.json|yaml]`. A source config file must already exist (`fablo init` creates one). `fablo up` starts the Hyperledger Fabric network, creates the channels, and installs and deploys chaincodes (package, install, approve and commit). If the generated `fablo-target` files are missing, `fablo up` generates them for you before starting.

Once the network has been generated, `fablo up` compares your config with the copy it stored in `fablo-target`. If the two differ, it stops with an error instead of starting, and you then run `fablo prune` to remove the old network, or `fablo recreate [/path/to/fablo-config.json|yaml]` to prune and start again with the new config in one step.

If you want to generate the network files without starting anything (for inspection, or to target a specific config or output directory), use:

```
fablo generate [/path/to/fablo-config.json|yaml [/path/to/fablo/target]]
```

The default output directory is `fablo-target` in your current directory.

## Step 3 — Tear Down the Network

When you're done, stop the network and clean up:

```
fablo down
```

This downs the Hyperledger Fabric network for the configuration in the current directory (similar to `docker-compose down`).

To also remove all generated files, use:

```
fablo prune
```

`prune` downs the network and removes everything that `generate`/`up` created, leaving you back at just your `fablo-config.json` (or `.yaml`).

## Fabric-X Getting Started Workflow

Fabric-X uses modular gRPC microservices and smart contract namespaces instead of the classic Fabric peer and chaincode architecture.

### Scope and Boundaries

When using `global.provider: "fabric-x"`, the network operates within the following boundaries:
- **Engine:** Docker Compose only (`kubernetes` is not supported).
- **Channels:** Exactly one channel is supported (default: `mychannel`).
- **Smart Contracts:** Classic chaincodes (`chaincodes[]`) are replaced by on-chain **namespaces** (`namespaces[]`).
- **Tooling:** Blockchain Explorer and Fablo REST are not supported for Fabric-X.
- **TLS:** `global.tls` must be `true`.

### Basic Workflow

A complete basic workflow for Fabric-X is:

```bash
fablo init fabric-x
fablo validate
fablo up
fablo namespace init
fablo namespace list
fablo stop
fablo reset
```

#### 1. Initialize Configuration

Generate the starter Fabric-X configuration:

```bash
fablo init fabric-x
```

This scaffolds `fablo-config.json` with:
- `global.provider`: `"fabric-x"` (Fabric version defaults to `3.1.0` and TLS enabled)
- Application organization `Org1`
- Single channel `mychannel` joined by `Org1`
- Namespace `mynamespace` governed by `Org1`
- 1-party orderer cluster (configured via `fabricX.orderer.partyCount: 1`, default)

#### 2. Validate Configuration

Validate the configuration against Fabric-X schema rules:

```bash
fablo validate
```

#### 3. Start the Network

Generate network artifacts and launch the containers:

```bash
fablo up
```

Fablo creates the required crypto material statically using `cryptogen` inside `fabric-x-tools`, generates the shared ordering configuration and genesis block, and starts the 10 microservice containers (4 ordering cluster services and 6 committer stack services in the default 1-party starter configuration; no runtime CA container is required) via Docker Compose.

#### 4. Initialize Namespaces

Fabric-X requires a committed namespace on the ledger before application transactions can be submitted or queried:

```bash
# Create all namespaces declared in fablo-config.json
fablo namespace init

# Or target only a specific namespace
fablo namespace init mynamespace
```

#### 5. List Namespaces

Query and verify committed namespaces on the running network:

```bash
# Query using default organization (first org)
fablo namespace list

# Or query using a specific organization's credentials
fablo namespace list Org1
```

#### 6. Lifecycle Management

- **Stop containers without removing data:**
  ```bash
  fablo stop
  ```
- **Resume stopped containers:**
  ```bash
  fablo start
  ```
- **Reset the network (wipes ledger state and crypto, then restarts fresh):**
  ```bash
  fablo reset
  ```
- **Tear down containers and remove volumes/crypto:**
  ```bash
  fablo down
  ```
- **Prune network and remove `fablo-target` entirely:**
  ```bash
  fablo prune
  ```

### Sample Configuration

For a complete working multi-organization Fabric-X configuration sample, see [samples/fablo-config-fabric-x-2orgs.json](https://github.com/hyperledger-labs/fablo/blob/main/samples/fablo-config-fabric-x-2orgs.json). You can also inspect the end-to-end test scripts in [test-08-fabric-x.sh](https://github.com/hyperledger-labs/fablo/blob/main/e2e-network/docker/test-08-fabric-x.sh) and [test-09-fabric-x-bft.sh](https://github.com/hyperledger-labs/fablo/blob/main/e2e-network/docker/test-09-fabric-x-bft.sh).

For a sample application interacting with the Fabric-X network via the Go SDK (`github.com/hyperledger/fabric-x-sdk`), see [samples/chaincodes/fabric-x-app](https://github.com/hyperledger-labs/fablo/tree/main/samples/chaincodes/fabric-x-app).
