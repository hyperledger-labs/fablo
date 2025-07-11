# Test cases

| Test case                 |    01-v2-simple    |   02-v2-raft-2orgs   | 03-v2-private-data |       04-v2-snapshot        |  test-05-v3  |  test-06-v3-bft |
| ------------------------- |:---------------:|:-----------:|:----------:|:------------------------:|:------------------:|:---------------------:|
| Fabric versions           |      2.4.7      |    2.3.2    |   2.5.9    |       2.3.3/2.4.2        |     3.0.0-beta     |      3.0.0-beta       |
| TLS                       |       no        |     yes     |     no     |           yes            |        yes         |          yes          |
| Channel capabilities      |       v2        |     v2      |    v2_5    |            v2            |        v3_0        |          v3_0         |
| Consensus                 |      solo       |    RAFT     |    solo    |           RAFT           |        RAFT        |          BFT          |
| Orderer nodes             |        1        |      3      |     1      |            1             |         3          |          4            |
| Organizations             |        1        |      2      |     2      |            1             |         1          |          1            |
| CA database               |     SQLite      |   SQLite    |   SQLite   |         Postgres         |        SQLite      |         SQLite        |
| Peer database             |     LevelDB     |   LevelDB   |  LevelDB   |         CouchDB          |        LevelDB     |         LevelDB       |
| Peer count                |        2        |    2, 2     |    2, 1    |            2             |          2         |          2            |
| Channels                  |        1        |      2      |     1      |            1             |          1         |          1            |
| Node chaincode            |       yes       |     yes     |    yes     |           yes            |         yes        |          yes          |
| Node chaincode upgrade    |       no        |     yes     |     no     |            no            |         no         |          no           |
| Node chaincode endorsement|       OR        |     OR      |  OR, AND   |         default          |         OR         |          OR           |
| Private data              |       no        |     no      |    yes     |           yes            |         no         |          no           |
| Java chaincode            |       no        |     yes     |     no     |            no            |         no         |          no           |
| Go chaincode              |       no        |     no      |     yes     |            no            |         no         |          no           |
| Tools                     | channel scripts | Fablo REST  |     -      |  Fablo REST, Explorer    |         -          |          -            |
| Other Fablo commands      |   init, reset   | stop, start |     -      | snapshot, prune, restore |         -          |          -            |
