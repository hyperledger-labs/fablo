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

For contributors running from source on Windows, this equivalent command avoids CRLF issues in `fablo.sh`:

```powershell
bash -lc "sed 's/\r$//' ./fablo.sh | bash -s -- up fablo-config.json"
```

## What this command does

`up` runs the full startup workflow:

- Generates missing artifacts in `fablo-target` (if not present).
- Generates crypto/config artifacts.
- Starts orderers, peers, CAs, and optional tools.
- Creates channels, installs/approves/commits chaincode definitions.

## Sample terminal output

```text
$ fablo up fablo-config.json
Executing Fablo Docker command: up
Generating basic configs
Generating crypto material for Orderer
Generating certs...
	CONFIG_PATH: /mnt/c/fablo/tmp-docs-snippets/fablo-target/fabric-config
Unable to find image 'ghcr.io/fablo-io/fabric-tools:3.1.3' locally
3.1.3: Pulling from fablo-io/fabric-tools
...
ClientWait -> txid [...] committed with status (VALID) at peer0.org1.example.com:7041

Done! Enjoy your fresh network
Executing post-start hook
```

## Expected output

- Running Fabric containers in Docker (`orderer`, `peer`, `ca`, and optional tools).
- Channels created and chaincodes installed/approved/committed based on config.
- A ready network that can be queried with `fablo chaincode query` or channel commands.

## When to use

- Running the full network from your current project config.
- Recreating a realistic local environment before app or chaincode development.
- Validating your config changes end-to-end before opening a pull request.
