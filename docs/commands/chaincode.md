# chaincode commands

Commands for installing, upgrading, invoking, and querying chaincodes.

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

## Example invoke

```bash
fablo chaincode invoke "peer0.org1.example.com" "my-channel1" "chaincode1" '{"Args":["KVContract:put", "name", "Willy Wonka"]}'
```

## Hot reload guidance

For development mode and CCaaS hot reload patterns, see the section in [README.md](../../README.md#achieving-chaincode-hot-reload).
