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

For contributors running from source on Windows, this equivalent command avoids CRLF issues in `fablo.sh`:

```powershell
bash -lc "sed 's/\r$//' ./fablo.sh | bash -s -- validate fablo-config.json"
```

## Sample terminal output

```text
$ fablo validate fablo-config.json
Validation errors count: 0
Validation warnings count: 0
===========================================================
```

## Common validation failure example

```text
Validation errors count: 1
- chaincodes[0].directory is required for lang=node
```

## Expected output

- Success: confirmation that config is valid.
- Failure: actionable validation errors printed in terminal.

## Tip

Run validate before generate or up to fail fast on config issues.

## When to use

- Before opening a PR with config/template changes.
- In CI pipelines to catch invalid topology changes early.
