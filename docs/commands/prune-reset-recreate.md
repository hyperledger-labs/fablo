# prune, reset, recreate

Commands for clean rebuild workflows.

## Syntax

```bash
fablo prune
fablo reset
fablo recreate [/path/to/fablo-config.json|yaml]
```

## Behavior

- prune: Stops network and removes fablo-target.
- reset: Recreates runtime state by running down + up while preserving generated setup.
- recreate: Removes target, regenerates files from config, then starts network.

## Example

```bash
fablo recreate fablo-config.json
```

## When to use

- prune: Full cleanup.
- reset: Fresh ledger state with same topology.
- recreate: Apply updated config changes end-to-end.
