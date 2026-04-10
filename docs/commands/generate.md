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

For contributors running from source on Windows, this equivalent command avoids CRLF issues in `fablo.sh`:

```powershell
bash -lc "sed 's/\r$//' ./fablo.sh | bash -s -- generate fablo-config.json"
```

## What gets generated

The command creates `fablo-target` with Docker orchestration scripts, Fabric config files, helper hooks, and topology output.

Typical generated files include:

- `fablo-target/fablo-config.json`
- `fablo-target/fabric-docker.sh`
- `fablo-target/network-topology.mmd`
- `fablo-target/fabric-config/configtx.yaml`
- `fablo-target/fabric-config/crypto-config-orderer.yaml`
- `fablo-target/fabric-config/crypto-config-org1.yaml`
- `fablo-target/fabric-config/connection-profiles/connection-profile-org1.json`

## Sample terminal output

```text
$ fablo generate fablo-config.json
Generating network config
	FABLO_VERSION:      2.5.0
	FABLO_CONFIG:       fablo-config.json
	FABLO_NETWORK_ROOT: /.../fablo-target
Setting up network based on config: fablo-config.json
Used network config: /network/workspace/fablo-config.json
Fabric version is: 3.1.0
Generating docker-compose network 'fablo_network_202604061753'...
✅ Network topology exported to /network/workspace/network-topology.mmd
Done & done !!! Try the network out:
-> fablo up - to start network
-> fablo help - to view all commands
Formatting generated files
Executing post-generate hook
```

## Expected output

- A fully generated `fablo-target` directory.
- No peer/orderer/CA containers are started.
- You can inspect and modify generated files before running `fablo up`.

## When to use

- Reviewing generated files before startup.
- Debugging configuration behavior (what config values resolve to in output files).
- Versioning generated artifacts for custom workflows and CI baselines.
