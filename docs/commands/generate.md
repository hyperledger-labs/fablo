# generate

Generates network artifacts from your Fablo config without starting the network.

## Syntax

```bash
fablo generate [/path/to/fablo-config.json|yaml [/path/to/fablo-target]]
```

## Parameters

- Config path (optional): Input JSON or YAML config.
- Target path (optional): Output directory for generated artifacts.

## Example

```bash
fablo generate fablo-config.yaml
```

## Expected output

- Generated scripts and Fabric configuration files in fablo-target.
- No running containers are started by this command.

## When to use

- Reviewing generated files before startup.
- Versioning generated artifacts for custom workflows.
