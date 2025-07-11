# Supported features

This document provides an overview of Fablo features. The table below tracks feature compatibility across different Fabric versions, testing status, documentation coverage, and links to relevant issues for ongoing development work.

---

| Feature                                | Fabric v2 | Fabric v3 | Documented | CI tests | Relevant issues |
|----------------------------------------|-----------|-----------|------------|----------|-----------------|
| <br>**NETWORK CONFIGURATION**          |           |           |            |          |                 |
| RAFT Consensus                         | ✓         | ✓         | ✓          | [02_v2](/e2e-network/docker/test-02-v2-raft-2orgs.sh) |                 |
| BFT Consensus                          | -         | ✓         | ✓          | [06_v3](/e2e-network/docker/test-06-v3-bft.sh) | [#559](https://github.com/hyperledger-labs/fablo/issues/559) |
| TLS                                    | ✓         | ✓         | ✓          | [01_v2](/e2e-network/docker/test-01-v2-simple.sh), [02_v2](/e2e-network/docker/test-02-v2-raft-2orgs.sh), [05_v3](/e2e-network/docker/test-05-v3.sh), [06_v3](/e2e-network/docker/test-06-v3-bft.sh) |                 |
| Orderer Groups                         | ✓         | ✕         | ✓          | [02_v2](/e2e-network/docker/test-02-v2-raft-2orgs.sh) | [#560](https://github.com/hyperledger-labs/fablo/issues/560) |
| Peer DB - LevelDB                      | ✓         | ✓         | ✓          | [01_v2](/e2e-network/docker/test-01-v2-simple.sh), [05_v3](/e2e-network/docker/test-05-v3.sh), [06_v3](/e2e-network/docker/test-06-v3-bft.sh) |                 |
| Peer DB - CouchDB                      | ✓         | ✓         | ✓          | [04_v2](/e2e-network/docker/test-04-v2-snapshot.sh) |                 |
| CA DB - SQLite                         | ✓         | ✓         | ✓          | [01_v2](/e2e-network/docker/test-01-v2-simple.sh), [05_v3](/e2e-network/docker/test-05-v3.sh), [06_v3](/e2e-network/docker/test-06-v3-bft.sh) |                 |
| CA DB - Postgres                       | ✓         | ✓         | ✓          | [04_v2](/e2e-network/docker/test-04-v2-snapshot.sh) |                 |
| CA DB - MySQL                          | ✕         | ✕         | ✓          |          | [#561](https://github.com/hyperledger-labs/fablo/issues/561) |
| <br>**CHANNELS**                       |           |           |            |          |                 |
| Channel query scripts                  | ✓         | ✓         |            | [01_v2](/e2e-network/docker/test-01-v2-simple.sh), [05_v3](/e2e-network/docker/test-05-v3.sh), [06_v3](/e2e-network/docker/test-06-v3-bft.sh) |                 |
| <br>**CHAINCODES**                     |           |           |            |          |                 |
| Node                                   | ✓         | ✓         |            | [01_v2](/e2e-network/docker/test-01-v2-simple.sh), [02_v2](/e2e-network/docker/test-02-v2-raft-2orgs.sh), [05_v3](/e2e-network/docker/test-05-v3.sh), [06_v3](/e2e-network/docker/test-06-v3-bft.sh) |                 |
| Go                                     | ✓         | ✓         |            |          |                 |
| Java                                   | ✓         | ✓         |            | [02_v2](/e2e-network/docker/test-02-v2-raft-2orgs.sh) |                 |
| Chaincode-as-a-Service (CCaaS)         | ✕         | ✕         |            |          |                 |
| Endorsement Policies                   | ✓         | ✓         |            | [03_v2](/e2e-network/docker/test-03-v2-private-data.sh), [02_v2](/e2e-network/docker/test-02-v2-raft-2orgs.sh) |                 |
| Multi-org Endorsements                 | ✓         | ✓         |            | [03_v2](/e2e-network/docker/test-03-v2-private-data.sh) |                 |
| Private Data Collections               | ✓         | ✓         |            | [03_v2](/e2e-network/docker/test-03-v2-private-data.sh) |                 |
| Chaincode scripts (list/query/invoke)  | ✓         | ✓         |            | [01_v2](/e2e-network/docker/test-01-v2-simple.sh), [02_v2](/e2e-network/docker/test-02-v2-raft-2orgs.sh), [03_v2](/e2e-network/docker/test-03-v2-private-data.sh), [04_v2](/e2e-network/docker/test-04-v2-snapshot.sh), [05_v3](/e2e-network/docker/test-05-v3.sh), [06_v3](/e2e-network/docker/test-06-v3-bft.sh) |                 |
| Commands: install / upgrade            | ✓         | ✓         |            | [02_v2](/e2e-network/docker/test-02-v2-raft-2orgs.sh) |                 |
| <br>**TOOLS**                          |           |           |            |          |                 |
| Fablo REST                             | ✓         | ✓         |            | [02_v2](/e2e-network/docker/test-02-v2-raft-2orgs.sh), [04_v2](/e2e-network/docker/test-04-v2-snapshot.sh) |                 |
| Explorer                               | ✓         | ✕         |            | [04_v2](/e2e-network/docker/test-04-v2-snapshot.sh) |                 |
| <br>**FABLO COMMANDS**                 |           |           |            |          |                 |
| `generate`                             | ✓         | ✓         | ✓          | [01_v2](/e2e-network/docker/test-01-v2-simple.sh), [02_v2](/e2e-network/docker/test-02-v2-raft-2orgs.sh), [05_v3](/e2e-network/docker/test-05-v3.sh), [06_v3](/e2e-network/docker/test-06-v3-bft.sh) |                 |
| `up`                                   | ✓         | ✓         | ✓          | [01_v2](/e2e-network/docker/test-01-v2-simple.sh), [02_v2](/e2e-network/docker/test-02-v2-raft-2orgs.sh), [05_v3](/e2e-network/docker/test-05-v3.sh), [06_v3](/e2e-network/docker/test-06-v3-bft.sh) |                 |
| `start`, `stop`, `restart`             | ✓         | ✓         | ✓          | [02_v2](/e2e-network/docker/test-02-v2-raft-2orgs.sh) |                 |
| `down`, `reset`                        | ✓         | ✓         | ✓          | [01_v2](/e2e-network/docker/test-01-v2-simple.sh), [02_v2](/e2e-network/docker/test-02-v2-raft-2orgs.sh), [05_v3](/e2e-network/docker/test-05-v3.sh), [06_v3](/e2e-network/docker/test-06-v3-bft.sh) |                 |
| `prune`, `recreate`                    | ✓         | ✓         | ✓          | [04_v2](/e2e-network/docker/test-04-v2-snapshot.sh) |                 |
| `validate`, `extend-config`            | ✓         | ✓         | ✓          |          |                 |
| `version`                              | ✓         | ✓         | ✓          |          |                 |
| `init` (node, rest, dev)               | ✓         | ✓         | ✓          | [01_v2](/e2e-network/docker/test-01-v2-simple.sh), [05_v3](/e2e-network/docker/test-05-v3.sh), [06_v3](/e2e-network/docker/test-06-v3-bft.sh) |                 |
| `export-network-topology` to Mermaid   | ✓         | ✓         | ✓          |          |                 |
| Other `init` options                   |           |           |            |          | [#444](https://github.com/hyperledger-labs/fablo/issues/444)      |
| <br>**SNAPSHOT**                       |           |           |            |          |                 |
| Create snapshot                        | ✓         | ✓         | ✓          | [04_v2](/e2e-network/docker/test-04-v2-snapshot.sh) |                 |
| Restore snapshot                       | ✓         | ✓         | ✓          | [04_v2](/e2e-network/docker/test-04-v2-snapshot.sh) |                 |
| Post-start hook                        |           |           |            |          | [#111](https://github.com/hyperledger-labs/fablo/issues/111) |
| <br>**OTHER FEATURES**                 |           |           |            |          |                 |
| Peer dev mode                          | ✓         | ✕         | ✓          |          | [#472](https://github.com/hyperledger-labs/fablo/issues/472) |
| Connection profiles                    | ✓         | ✓         | ✓          |          |                 |
| Gateway client                         |           |           |            |          | [#544](https://github.com/hyperledger-labs/fablo/pull/544) |
| Hooks: post-generate                   | ✓         | ✓         | ✓          |          |                 |
| JSON/YAML support                      | ✓         | ✓         | ✓          |          |                 |

---

**Supported Fabric versions:**

Fabric v2 = 2.5.12<br>
Fabric v3 = 3.0.0

**Legend:**

✓ = supported<br>
✕ = not supported<br>
<span>-</span> = not applicable