# init

Creates a starter Fablo configuration in the current directory.

## Syntax

```bash
fablo init [node] [rest] [dev] [gateway]
```

## Parameters

- node: Adds sample Node.js chaincode.
- rest: Enables Fablo REST container.
- dev: Enables development workflow for chaincode hot reload.
- gateway: Adds sample Node.js gateway app.

## Example

```bash
fablo init node rest
```

## What gets generated

- `fablo-config.json`
- `chaincodes/chaincode-kv-node/.nvmrc`
- `chaincodes/chaincode-kv-node/Dockerfile`
- `chaincodes/chaincode-kv-node/index.js`
- `chaincodes/chaincode-kv-node/package.json`
- `chaincodes/chaincode-kv-node/package-lock.json`

## Sample terminal output

```text
$ fablo init node rest
Sample config file created! :)
You can start your network with 'fablo up' command
========================================
```

## Expected output

- A generated `fablo-config.json` with a ready-to-run two-org sample topology.
- Optional sample assets depending on selected flags (for this example: Node chaincode and REST-enabled org settings).

## Sample generated config snippet

```json
{
	"$schema": "https://github.com/hyperledger-labs/fablo/releases/download/2.5.0/schema.json",
	"global": {
		"fabricVersion": "3.1.0",
		"tls": true,
		"peerDevMode": false,
		"engine": "docker"
	},
	"orgs": [
		{
			"organization": {
				"name": "Orderer",
				"domain": "orderer.example.com",
				"mspName": "OrdererMSP"
			},
			"ca": {
				"prefix": "ca",
				"db": "sqlite"
			},
			"orderers": [
				{
					"groupName": "group1",
					"type": "BFT",
					"instances": 2,
					"prefix": "orderer"
				}
			],
			"tools": {
				"fabloRest": true
			}
		}
	]
}
```

## When to use

- Starting a new local Fabric playground quickly.
- Bootstrapping an example config before customization.
- Creating a reproducible starter layout for workshops, demos, or onboarding.
