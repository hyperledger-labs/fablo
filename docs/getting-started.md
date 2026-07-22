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

This writes a `fablo-config.json` file describing a simple Hyperledger Fabric network — an orderer organization and one peer organization (`Org1`), a single channel (`my-channel1`), and no chaincodes.

If you want extra scaffolding alongside the config, pass one or more options (order doesn't matter):

```
fablo init node
fablo init node dev
fablo init gateway
fablo init rest
```

- `node` — copies a sample Node.js chaincode into `chaincodes/chaincode-kv-node` and registers it in the config.
- `dev` — used together with `node`, configures the chaincode to run in dev mode (CCAAS-based, with a watch/start command) instead of being installed normally.
- `gateway` — copies a sample Node.js gateway app into a `gateway` directory.
- `rest` — enables the Fablo REST tooling for each organization in the config.

`node` and `dev` cannot be combined with `ccaas`.

## Step 2 — Generate and Start the Network with `fablo up`

Start the network defined by your config:

```
fablo up
```

By default this looks for `fablo-config.json` or `fablo-config.yaml` in the current directory. `fablo up` starts the Hyperledger Fabric network, creates the channels, and installs and instantiates the chaincodes. If the network configuration hasn't been generated yet, `fablo up` generates it for you automatically before starting.

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
