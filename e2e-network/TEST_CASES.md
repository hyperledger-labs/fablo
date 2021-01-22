# Test cases

| Test case                 | 01    | 02    |
| ------------------------- |:-----:|:-----:|
| Fabric version            | 1.4.6 | 1.4.6 |
| TLS                       | no    | yes   |
| Channel capabilities      | v1_4_3| v1_4_3|
| Consensus                 | solo  | RAFT  |
| Orderer nodes             | 1     | 3     |
| Organizations             | 1     | 2     |
| Peers                     | 2     | 2, 2  |
| Channels                  | 1     | 2     |
| Node chaincode            | yes   | yes   |
| Node chaincode upgrade    | no    | yes   |
| Node chaincode endorsement| OR    | AND   |
| Java chaincode            | no    | yes   |
| Java chaincode endorsement| -     | OR    |
| Go chaincode              | no    | no    |
| Network restart           | no    | yes   |
