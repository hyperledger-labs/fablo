# chaincode commands

Commands for installing, upgrading, invoking, and querying chaincodes.

For contributors running from source on Windows, this equivalent command avoids CRLF issues in `fablo.sh`:

```powershell
bash -lc "sed 's/\r$//' ./fablo.sh | bash -s -- chaincodes list peer0.org1.example.com my-channel1"
```

## Install all chaincodes

```bash
fablo chaincodes install
```

## Install one chaincode

```bash
fablo chaincode install <chaincode-name> <version>
```

## Upgrade chaincode

```bash
fablo chaincode upgrade <chaincode-name> <version>
```

## Invoke

```bash
fablo chaincode invoke <peers-domains-comma-separated> <channel-name> <chaincode-name> <command> [transient]
```

## Query

```bash
fablo chaincode query <peer-domain> <channel-name> <chaincode-name> <command> [transient]
```

## List

```bash
fablo chaincodes list <peer> <channel>
```

## Sample terminal output (chaincodes list)

```text
$ fablo chaincodes list peer0.org1.example.com my-channel1
Executing Fablo Docker command: chaincodes
Chaincodes list:
	PEER_ADDRESS: peer0.org1.example.com:7041
	CHANNEL_NAME: my-channel1
	CA_CERT: crypto-orderer/tlsca.orderer.example.com-cert.pem
...
Committed chaincode definitions on channel 'my-channel1':
Name: chaincode1, Version: 0.0.1, Sequence: 1
```

## Example invoke

```bash
fablo chaincode invoke "peer0.org1.example.com" "my-channel1" "chaincode1" '{"Args":["KVContract:put", "name", "Willy Wonka"]}'
```

## Hot reload guidance

For development mode and CCaaS hot reload patterns, see the section in [README.md](../../README.md#achieving-chaincode-hot-reload).

## When to use

- `chaincodes install` when chaincode startup failed during `fablo up`.
- `chaincode upgrade` after changing chaincode code or metadata version.
- `chaincode invoke/query` during integration testing and local debugging.
