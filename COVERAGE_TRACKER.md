# 🧪 Fablo Feature Coverage Tracker

This document tracks the progress of testing and documenting Fablo features across different Fabric versions.

Legend:  
❔ = unknown status <br>
✅ = completed  
❌ = not done  
🔄 = in progress  
🔗 = link to related issue/todo  

---

## Network Topology

| Feature                          | Fabric v2 | Fabric v3 | Tested | Documented | Todo / Issue        |
|----------------------------------|-----------|-----------|--------|-------------|----------------------|
| Solo Consensus                   | ❔        | ❔        | ❔     | ❔          | [#TODO](#)           |
| RAFT Consensus                   | ❔        | ❔        | ❔     | ❔          | [#TODO](#)           |
| BFT Consensus                    | ❔        | ❔        | ❔     | ❔          | [#TODO](#)           |
| TLS                              | ❔        | ❔        | ❔     | ❔          |                      |
| Orderer Groups                   | ❔        | ❔        | ❔     | ❔          | [#TODO](#)           |
| Peer DB - LevelDB                | ❔        | ❔        | ❔     | ❔          |                      |
| Peer DB - CouchDB                | ❔        | ❔        | ❔     | ❔          |                      |
| CA DB - SQLite                   | ❔        | ❔        | ❔     | ❔          |                      |
| CA DB - Postgres                 | ❔        | ❔        | ❔     | ❔          | [#TODO](#)           |
| CA DB - MySQL                    | ❔        | ❔        | ❔     | ❔          | [#TODO](#)           |

---

## Channels

| Feature                 | Fabric v2 | Fabric v3 | Tested | Documented | Todo / Issue        |
|-------------------------|-----------|-----------|--------|-------------|----------------------|
| Channel query scripts   | ❔        | ❔        | ❔     | ❔          |                      |

---

## Chaincodes

| Feature                           | Fabric v2 | Fabric v3 | Tested | Documented | Todo / Issue        |
|-----------------------------------|-----------|-----------|--------|-------------|----------------------|
| Node                              | ❔        | ❔        | ❔     | ❔          |                      |
| Go                                | ❔        | ❔        | ❔     | ❔          |                      |
| Java                              | ❔        | ❔        | ❔     | ❔          | [#TODO](#)           |
| Chaincode-as-a-Service (CCaaS)    | ❔        | ❔        | ❔     | ❔          |                      |
| Endorsement Policies              | ❔        | ❔        | ❔     | ❔          |                      |
| Multi-org Endorsements            | ❔        | ❔        | ❔     | ❔          |                      |
| Private Data Collections          | ❔        | ❔        | ❔     | ❔          |                      |
| Chaincode scripts (list/query/invoke) | ❔    | ❔        | ❔     | ❔          |                      |
| Commands: install / upgrade       | ❔        | ❔        | ❔     | ❔          |                      |

---

## Tools

| Feature       | Fabric v2 | Fabric v3 | Tested | Documented | Todo / Issue        |
|---------------|-----------|-----------|--------|-------------|----------------------|
| Fablo REST    | ❔        | ❔        | ❔     | ❔          |                      |
| Explorer      | ❔        | ❔        | ❔     | ❔          | [#TODO](#)           |

---

## Fablo Commands

| Feature                                | Fabric v2 | Fabric v3 | Tested | Documented | Todo / Issue        |
|----------------------------------------|-----------|-----------|--------|-------------|----------------------|
| `generate`                             | ❔        | ❔        | ❔     | ❔          |                      |
| `up`, `start`, `stop`, `down`, `reset`, `recreate` | ❔ | ❔ | ❔ | ❔  |                      |
| `validate`, `extendConfig`             | ❔        | ❔        | ❔     | ❔          |                      |
| `update`, `version`                    | ❔        | ❔        | ❔     | ❔          |                      |
| `init` (node, rest, dev)               | ❔        | ❔        | ❔     | ❔          |                      |
| Other init options                     | ❔        | ❔        | ❔     | ❔          | [#TODO](#)           |

---

## Snapshot

| Feature               | Fabric v2 | Fabric v3 | Tested | Documented | Todo / Issue        |
|------------------------|-----------|-----------|--------|-------------|----------------------|
| Create snapshot        | ❔        | ❔        | ❔     | ❔          |                      |
| Restore snapshot       | ❔        | ❔        | ❔     | ❔          |                      |
| Post-restore hook      | ❔        | ❔        | ❔     | ❔          | [#TODO](#)           |

---

## Other Features

| Feature                | Fabric v2 | Fabric v3 | Tested | Documented | Todo / Issue        |
|------------------------|-----------|-----------|--------|-------------|----------------------|
| Peer dev mode          |✅         |❌         |  ❌    |✅           |[Support dev mode for Fabric v3](https://github.com/hyperledger-labs/fablo/issues/472)                      |
| Connection profiles    |✅         |✅         |✅      |✅           |                      |
| Gateway client         | ❔        | ❔        | ❔     | ❔          |[Adds gateway option to init](https://github.com/hyperledger-labs/fablo/pull/544)                      |
| Hooks: post-generate   |✅         |✅         |✅      |✅           |                      |
| JSON/YAML support      |✅         |✅         |✅      |✅           |                      |