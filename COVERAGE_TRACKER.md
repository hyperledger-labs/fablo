# Supported features

This document provides an overview of Fablo features. The table below tracks feature compatibility across different Fabric versions, testing status, documentation coverage, and links to relevant issues for ongoing development work.

---

| Feature                                | Fabric v2 | Fabric v3 | Documented | CI tests | Relevant issues |
|----------------------------------------|-----------|-----------|------------|----------|-----------------|
| <br>**NETWORK CONFIGURATION**          |           |           |            |          |                 |
| RAFT Consensus                         | ✓         | ✓         | ✓          |          |                 |
| BFT Consensus                          | -         | ✓         | ✓          | [05_v3](/e2e-network/docker/test-06-v3-bft.sh) | [#559](https://github.com/hyperledger-labs/fablo/issues/559) |
| TLS                                    | ✓         | ✓         | ✓          |          |                 |
| Orderer Groups                         | ✓         | 𐄂         | ✓          |          | [#560](https://github.com/hyperledger-labs/fablo/issues/560) |
| Peer DB - LevelDB                      | ✓         | ✓         | ✓          |          |                 |
| Peer DB - CouchDB                      | ✓         | ✓         | ✓          |          |                 |
| CA DB - SQLite                         | ✓         | ✓         | ✓          |          |                 |
| CA DB - Postgres                       | ✓         | ✓         | ✓          |          |                 |
| CA DB - MySQL                          | 𐄂         | 𐄂         | ✓          |          | [#561](https://github.com/hyperledger-labs/fablo/issues/561) |
| <br>**CHANNELS**                       |           |           |            |          |                 |
| Channel query scripts                  | ✓         | ✓         |            |          |                 |
| <br>**CHAINCODES**                     |           |           |            |          |                 |
| Node                                   | ✓         | ✓         |            |          |                 |
| Go                                     | ✓         | ✓         |            |          |                 |
| Java                                   | ✓         | ✓         |            |          |                 |
| Chaincode-as-a-Service (CCaaS)         | 𐄂         | 𐄂         |            |          |                 |
| Endorsement Policies                   | ✓         | ✓         |            |          |                 |
| Multi-org Endorsements                 | ✓         | ✓         |            |          |                 |
| Private Data Collections               | ✓         | ✓         |            |          |                 |
| Chaincode scripts (list/query/invoke)  | ✓         | ✓         |            |          |                 |
| Commands: install / upgrade            | ✓         | ✓         |            |          |                 |
| <br>**TOOLS**                          |           |           |            |          |                 |
| Fablo REST                             | ✓         | ✓         |            |          |                 |
| Explorer                               | ✓         | 𐄂         |            |          |                 |
| <br>**FABLO COMMANDS**                 |           |           |            |          |                 |
| `generate`                             | ✓         | ✓         | ✓          |          |                 |
| `up`                                   | ✓         | ✓         | ✓          |          |                 |
| `start`, `stop`, `restart`             | ✓         | ✓         | ✓          |          |                 |
| `down`, `reset`                        | ✓         | ✓         | ✓          |          |                 |
| `prune`, `recreate`                    | ✓         | ✓         | ✓          |          |                 |
| `validate`, `extend-config`            | ✓         | ✓         | ✓          |          |                 |
| `version`                              | ✓         | ✓         | ✓          |          |                 |
| `init` (node, rest, dev)               | ✓         | ✓         | ✓          |          |                 |
| `export-network-topology` to Mermaid   | ✓         | ✓         | ✓          |          |                 |
| Other `init` options                   |           |           |            |          | [#444](https://github.com/hyperledger-labs/fablo/issues/444)      |
| <br>**SNAPSHOT**                       |           |           |            |          |                 |
| Create snapshot                        | ✓         | ✓         | ✓          |          |                 |
| Restore snapshot                       | ✓         | ✓         | ✓          |          |                 |
| Post-start hook                        |           |           |            |          | [#111](https://github.com/hyperledger-labs/fablo/issues/111) |
| <br>**OTHER FEATURES**                 |           |           |            |          |                 |
| Peer dev mode                          | ✓         | 𐄂         | ✓          |          | [#472](https://github.com/hyperledger-labs/fablo/issues/472) |
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
𐄂 = not supported<br>
- = not applicable