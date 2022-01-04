# Test cases

| Test case                 | 01-simple | 02-raft   | 03-private| 04-snapshot |
| ------------------------- |:---------:|:---------:|:---------:|:-----------:|
| Fabric versions           | 2.4.0     | 2.3.2     | 1.4.11    | 2.3.3       |
| TLS                       | no        | yes       | no        | yes         |
| Channel capabilities      | v2        | v2        | v1_4_3    | v2          |
| Consensus                 | solo      | RAFT      | solo      | RAFT        |
| Orderer nodes             | 1         | 3         | 1         | 1           |
| Organizations             | 1         | 2         | 2         | 1           |
| CA database               | SQLite    | SQLite    | SQLite    | Postgres    |
| Peer database             | LevelDB   | LevelDB   | LevelDB   | CouchDB     |
| Peer count                | 2         | 2, 2      | 2, 1      | 2           |
| Channels                  | 1         | 2         | 1         | 1           |
| Node chaincode            | yes       | yes       | yes       | yes         |
| Node chaincode upgrade    | no        | yes       | no        | no          |
| Node chaincode endorsement| OR        | OR        | OR, AND   | default     |
| Private data              | no        | no        | yes       | yes         |
| Java chaincode            | no        | yes       | no        | no          |
| Go chaincode              | no        | no        | no        | no          |
| Tools                     | -         | Fablo REST| -         | Fablo REST, Explorer|
| Other Fablo commands      | init, reset | stop, start | -     | snapshot, prune, restore  |
