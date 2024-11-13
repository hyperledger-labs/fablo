# Test cases

| Test case                 |    01-simple    |   02-raft   | 03-private |       04-snapshot        |  test-05-version3  |
| ------------------------- |:---------------:|:-----------:|:----------:|:------------------------:|:------------------:|
| Fabric versions           |      2.4.7      |    2.3.2    |   2.4.7    |       2.3.3/2.4.2        |     3.0.0-beta     |
| TLS                       |       no        |     yes     |     no     |           yes            |        yes         |
| Channel capabilities      |       v2        |     v2      |    v2_5    |            v2            |        v3_0        |
| Consensus                 |      solo       |    RAFT     |    solo    |           RAFT           |        RAFT        |
| Orderer nodes             |        1        |      3      |     1      |            1             |         1          |
| Organizations             |        1        |      2      |     2      |            1             |         1          |
| CA database               |     SQLite      |   SQLite    |   SQLite   |         Postgres         |        Postgres    |
| Peer database             |     LevelDB     |   LevelDB   |  LevelDB   |         CouchDB          |        CouchDB     |
| Peer count                |        2        |    2, 2     |    2, 1    |            2             |          2         |
| Channels                  |        1        |      2      |     1      |            1             |          1         |
| Node chaincode            |       yes       |     yes     |    yes     |           yes            |         yes        |
| Node chaincode upgrade    |       no        |     yes     |     no     |            no            |         no         |
| Node chaincode endorsement|       OR        |     OR      |  OR, AND   |         default          |         OR         |
| Private data              |       no        |     no      |    yes     |           yes            |         no         |
| Java chaincode            |       no        |     yes     |     no     |            no            |         no         |
| Go chaincode              |       no        |     no      |     no     |            no            |         no         |
| Tools                     | channel scripts | Fablo REST  |     -      |  Fablo REST, Explorer    |   channel scripts  |
| Other Fablo commands      |   init, reset   | stop, start |     -      | snapshot, prune, restore |     init, reset    |
