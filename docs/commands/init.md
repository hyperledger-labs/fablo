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

## Expected output

- A new fablo-config.json file.
- Optional sample chaincode and/or gateway files, based on selected flags.

## When to use

- Starting a new local Fabric playground quickly.
- Bootstrapping an example config before customization.
