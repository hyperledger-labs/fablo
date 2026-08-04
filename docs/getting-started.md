---
layout: doc
title: Getting started
---


# Set Up Your First Fablo Network

**Outline**
1. What You'll Need
2. Step 1 — Scaffold a Config with `fablo init`
3. Step 2 — Generate and Start the Network with `fablo up`
4. Step 3 — Tear Down the Network (`down` / `prune`)


## What You'll Need

- Fablo installed and available on your command line.
- A working directory where Fablo can create its configuration and generated network files.

## Step 1 — Scaffold a Config with `fablo init`

Create a starting configuration file in your current directory:

```
fablo init
```

This writes a `fablo-config.json` describing a simple Hyperledger Fabric network:

- Fabric version `3.1.0` with TLS enabled
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
- `dev` — used together with `node`, configures the chaincode to run in hot-reload / CCaaS-style dev mode instead of a normal install.
- `ccaas` — adds a sample chaincode-as-a-service definition. Cannot be combined with `node` or `dev`.
- `gateway` — copies a sample Node.js gateway app into a `gateway` directory (separate from Fablo REST).
- `rest` — enables [Fablo REST](https://github.com/fablo-io/fablo-rest) for each organization in the config.

You can also override generated fields with `--set`:

```
fablo init --set global.fabricVersion=2.5.0
fablo init --set global.monitoring.loglevel=debug --set orgs[1].peer.db=CouchDb
fablo init node --set orgs[1].peer.instances=5
```

Use `orgs[1]` for peer settings — `orgs[0]` is the orderer organization and has no `peer` block. Creating only `peer.db` without `peer.instances` is also invalid.

## Step 2 — Generate and Start the Network with `fablo up`

Start the network defined by your config:

```
fablo up
```

By default this looks for `fablo-config.json` or `fablo-config.yaml` in the current directory. A source config file must already exist (`fablo init` creates one). `fablo up` starts the Hyperledger Fabric network, creates the channels, and installs and deploys chaincodes (package / install / approve / commit). If the generated `fablo-target` files are missing, `fablo up` generates them for you before starting.

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
