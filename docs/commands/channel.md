# channel commands

Read channel state and fetch blocks/config from a peer context.

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

## Expected output

- Lists, JSON files, or block files depending on selected subcommand.
