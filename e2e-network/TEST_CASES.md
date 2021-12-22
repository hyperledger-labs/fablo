# Test cases

| Test case                 | 01-simple | 02-raft   | 03-private| 04-snapshot | 05-raft-explorer |
| ------------------------- |:---------:|:---------:|:---------:|:-----------:|:----------------:|
| Fabric versions           | 2.4.0     | 2.3.2     | 1.4.11    | 2.3.3       | 2.3.2            |
| TLS                       | no        | yes       | no        | yes         | yes              |
| Channel capabilities      | v2        | v2        | v1_4_3    | v2          | v2               |
| Consensus                 | solo      | RAFT      | solo      | RAFT        | RAFT             |            
| Orderer nodes             | 1         | 3         | 1         | 1           | 2                |
| Organizations             | 1         | 2         | 2         | 1           | 3                |
| Peers                     | 2         | 2, 2      | 2, 1      | 2           | 2, 2, 2          |
| Channels                  | 1         | 2         | 1         | 1           | 3                |
| Node chaincode            | yes       | yes       | yes       | yes         | yes              |
| Node chaincode upgrade    | no        | yes       | no        | no          | no               |
| Node chaincode endorsement| OR        | OR        | OR, AND   | default     | default          |
| Private data              | no        | no        | yes       | yes         | no               |
| Java chaincode            | no        | yes       | no        | no          | no               |
| Go chaincode              | no        | no        | no        | no          | no               |
| Fablo REST                | no        | yes       | no        | yes         | no               |
| Explorer                  | no        | no        | no        | no          | yes              |
| Other Fablo commands      | init, reset | stop, start | -     | snapshot, prune, restore  | -  |
