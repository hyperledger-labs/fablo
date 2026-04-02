# up

Generates (if needed) and starts the Fabric network.

## Syntax

```bash
fablo up [/path/to/fablo-config.json|yaml]
```

## Parameters

- Config path (optional): Input config file.

## Example

```bash
fablo up
```

## Expected output

- Network containers are created and started.
- Channels are created and chaincodes are installed/instantiated according to config.

## When to use

- Running the full network from your current project config.
