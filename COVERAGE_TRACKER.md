# Supported features

This document tracks the progress of testing and documenting Fablo features across different Fabric versions.

Legend:  
❔ = unknown status <br>
✅ = completed  
❌ = not done  
🔄 = in progress  
🔗 = link to related issue/todo

Fabric v2 = 2.5.9  
Fabric v3 = 3.0.0  

---

| Feature                                | Fabric v2 | Fabric v3 | Tested | Documented | Relevant issues                              |
|----------------------------------------|-----------|-----------|--------|-------------|-------------------------------------------|
| <br>**NETWORK CONFIGURATION**          |           |           |        |             |                                           |
| Solo Consensus                         | ✅        |           | ✅     | ✅          |                                           |
| RAFT Consensus                         | ✅        | ✅        | ✅     | ✅          |                                           |
| BFT Consensus                          | ❌        | ✅        | ✅     | ✅          | [#559](https://github.com/hyperledger-labs/fablo/issues/559) |
| TLS                                    | ✅        | ✅        | ✅     | ✅          |                                           |
| Orderer Groups                         | ✅        | ❌        | ✅     | ✅          | [#560](https://github.com/hyperledger-labs/fablo/issues/560) |
| Peer DB - LevelDB                      | ✅        | ✅        | ✅     | ✅          |                                           |
| Peer DB - CouchDB                      | ✅        | ✅        | ✅     | ✅          |                                           |
| CA DB - SQLite                         | ✅        | ✅        | ✅     | ✅          |                                           |
| CA DB - Postgres                       | ✅        | ✅        | ✅     | ✅          |                                           |
| CA DB - MySQL                          | ❌        | ❌        | ❌     | ✅          | [#561](https://github.com/hyperledger-labs/fablo/issues/561) |
| <br>**CHANNELS**                       |           |           |        |             |                                           |
| Channel query scripts                  | ✅        | ✅        | ✅     | ❔          |                                           |
| <br>**CHAINCODES**                     |           |           |        |             |                                           |
| Node                                   | ✅        | ✅        | ✅     | ❔          |                                           |
| Go                                     | ✅        | ✅        | ✅     | ❔          |                                           |
| Java                                   | ✅        | ✅        | ✅     | ❔          |                                           |
| Chaincode-as-a-Service (CCaaS)         | ❌        | ❌        | ✅     | ❔          |                                           |
| Endorsement Policies                   | ✅        | ✅        | ✅     | ❔          |                                           |
| Multi-org Endorsements                 | ✅        | ✅        | ✅     | ❔          |                                           |
| Private Data Collections               | ✅        | ✅        | ✅     | ❔          |                                           |
| Chaincode scripts (list/query/invoke)  | ✅        | ✅        | ✅     | ❔          |                                           |
| Commands: install / upgrade            | ✅        | ✅        | ✅     | ❔          |                                           |
| <br>**TOOLS**                          |           |           |        |             |                                           |
| Fablo REST                             | ✅        | ✅        | ✅     | ❔          |                                           |
| Explorer                               | ✅        | ❌        | ✅     | ❔          |                                           |
| <br>**FABLO COMMANDS**                 |           |           |        |             |                                           |
| `generate`                             | ❔        | ❔        | ❔     | ❔          |                                           |
| `up`, `start`, `stop`, `down`, `reset`, `recreate` | ❔ | ❔   | ❔     | ❔          |                                           |
| `validate`, `extendConfig`             | ❔        | ❔        | ❔     | ❔          |                                           |
| `update`, `version`                    | ❔        | ❔        | ❔     | ❔          |                                           |
| `init` (node, rest, dev)               | ❔        | ❔        | ❔     | ❔          |                                           |
| Other init options                     | ❔        | ❔        | ❔     | ❔          | [#TODO](#)                                |
| <br>**SNAPSHOT**                       |           |           |        |             |                                           |
| Create snapshot                        | ✅        | ✅        | ✅     | ✅          |                                           |
| Restore snapshot                       | ✅        | ✅        | ✅     | ✅          |                                           |
| Post-start hook                        | ❔        | ❔        | ❔     | ❔          | [#111](https://github.com/hyperledger-labs/fablo/issues/111) |
| <br>**OTHER FEATURES**                 |           |           |        |             |                                           |
| Peer dev mode                          | ✅        | ❌        | ❌     | ✅          | [#472](https://github.com/hyperledger-labs/fablo/issues/472) |
| Connection profiles                    | ✅        | ✅        | ✅     | ✅          |                                           |
| Gateway client                         | ❔        | ❔        | ❔     | ❔          | [#544](https://github.com/hyperledger-labs/fablo/pull/544) |
| Hooks: post-generate                   | ✅        | ✅        | ✅     | ✅          |                                           |
| JSON/YAML support                      | ✅        | ✅        | ✅     | ✅          |                                           |