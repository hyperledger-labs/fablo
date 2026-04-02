# validate

Validates a Fablo configuration file.

## Syntax

```bash
fablo validate [/path/to/fablo-config.json|yaml]
```

## What it checks

- JSON schema compatibility.
- Critical config consistency and required fields.

## Example

```bash
fablo validate fablo-config.yaml
```

## Expected output

- Success: confirmation that config is valid.
- Failure: actionable validation errors printed in terminal.

## Tip

Run validate before generate or up to fail fast on config issues.
