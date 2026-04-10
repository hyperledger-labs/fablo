# snapshot and restore

Backs up and restores network state artifacts.

## Syntax

```bash
fablo snapshot <target-snapshot-path>
fablo restore <source-snapshot-path>
```

## Behavior

- snapshot: Creates a .fablo.tar.gz archive with network state and certificates.
- restore: Restores snapshot into current working directory.

## Example flow

```bash
fablo snapshot /tmp/my-snapshot
fablo prune
fablo restore /tmp/my-snapshot
fablo start
```

## Notes

- Snapshot does not include your source config and chaincode source directories.
- For external chaincodes, run chaincodes install after restore.
