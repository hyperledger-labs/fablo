# export-network-topology

Exports network topology as Mermaid diagram source.

## Syntax

```bash
fablo export-network-topology [/path/to/fablo-config.json] [outputFile.mmd]
```

## Parameters

- Config path (optional): Input config.
- outputFile.mmd (optional): Output Mermaid file path. Default is network-topology.mmd.

## Example

```bash
fablo export-network-topology fablo-config.json network-topology.mmd
```

## Expected output

- Mermaid file that can be rendered by Mermaid-compatible tools.
