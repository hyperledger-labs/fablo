# Test cases

| Test case                 | 01-simple | 02-raft   | 03-private|
| ------------------------- |:---------:|:---------:|:---------:|
| Fabric versions           | 2.2.1     | 1.4.6     | 1.4.11    |
| TLS                       | no        | yes       | no        |
| Channel capabilities      | -         | v1_4_3    | v1_4_3    |
| Consensus                 | solo      | RAFT      | solo      |
| Orderer nodes             | 1         | 3         | 1         |
| Organizations             | 1         | 2         | 2         |
| Peers                     | 2         | 2, 2      | 2, 1      |
| Channels                  | 1         | 2         | 1         |
| Node chaincode            | yes       | yes       | yes       |
| Node chaincode upgrade    | yes       | yes       | no        |
| Node chaincode endorsement| OR        | OR        | OR, AND   |
| Private data              | no        | no        | yes       |
| Java chaincode            | no        | yes       | no        |
| Go chaincode              | no        | no        | no        |
| Other Fabrica commands    | init, reboot | stop, start | -    |
