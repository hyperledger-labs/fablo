# channel commands

Read channel state and fetch blocks/config from a peer context.

For contributors running from source on Windows, this equivalent command avoids CRLF issues in `fablo.sh`:

```powershell
bash -lc "sed 's/\r$//' ./fablo.sh | bash -s -- channel list org1 peer0"
```

## Help

```bash
fablo channel --help
```

## List channels

```bash
fablo channel list org1 peer0
```

## Channel info

```bash
fablo channel getinfo channel_name org1 peer0
```

## Fetch decoded config

```bash
fablo channel fetch config channel_name org1 peer0 [file_name.json]
```

## Fetch raw block

```bash
fablo channel fetch <oldest|newest|block-number> channel_name org1 peer0 [file_name.json]
```

## Sample terminal output (channel list)

```text
$ fablo channel list org1 peer0
Executing Fablo Docker command: channel
Listing channels using cli.org1.example.com using peer peer0.org1.example.com:7041 (TLS)...
...
Channels peers has joined:
my-channel1
```

## Expected output

- Lists, JSON files, or block files depending on selected subcommand.

## When to use

- Verifying that peers joined expected channels after `fablo up`.
- Fetching channel config for update workflows.
- Troubleshooting channel state during integration tests.
