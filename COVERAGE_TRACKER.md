# 🧪 Fablo Feature Coverage Tracker

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

## Network Topology

| Feature                          | Fabric v2 | Fabric v3 | Tested | Documented |                              Todo / Issue                              |
|----------------------------------|-----------|-----------|--------|-------------|-----------------------------------------------------------------------|
| Solo Consensus                   | ✅        | ❌        | ✅     | ✅          |                                                                       |
| RAFT Consensus                   | ✅        | ✅        | ✅     | ✅          |                                                                       |
| BFT Consensus                    | ❌        | ✅        | ✅     | ✅          | [559](https://github.com/hyperledger-labs/fablo/issues/559)           |
| TLS                              | ✅        | ✅        | ✅     | ✅          |                                                                       |
| Orderer Groups                   | ✅        | ❌        | ✅     | ✅          | [560](https://github.com/hyperledger-labs/fablo/issues/560)           |
| Peer DB - LevelDB                | ✅        | ✅        | ✅     | ✅          |                                                                       |
| Peer DB - CouchDB                | ✅        | ✅        | ✅     | ✅          |                                                                       |
| CA DB - SQLite                   | ✅        | ✅        | ✅     | ✅          |                                                                       |
| CA DB - Postgres                 | ✅        | ✅        | ✅     | ✅          |                                                                       |
| CA DB - MySQL                    | ❌        | ❌        | ❌     | ✅          | [561](https://github.com/hyperledger-labs/fablo/issues/561)           |

---

## Channels

| Feature                 | Fabric v2 | Fabric v3 | Tested | Documented | Todo / Issue        |
|-------------------------|-----------|-----------|--------|-------------|----------------------|
| Channel query scripts   | ✅        | ✅        | ✅     | ❔          |                      |

---

## Chaincodes

| Feature                           | Fabric v2 | Fabric v3 | Tested | Documented | Todo / Issue        |
|-----------------------------------|-----------|-----------|--------|-------------|----------------------|
| Node                              | ✅        | ✅        | ✅     | ❔          |                      |
| Go                                | ✅        | ✅        | ✅     | ❔          |                      |
| Java                              | ✅        | ✅        | ✅     | ❔          |                      |
| Chaincode-as-a-Service (CCaaS)    | ❌        | ❌        | ✅     | ❔          |                      |
| Endorsement Policies              | ✅        | ✅        | ✅     | ❔          |                      |
| Multi-org Endorsements            | ✅        | ✅        | ✅     | ❔          |                      |
| Private Data Collections          | ✅        | ✅        | ✅     | ❔          |                      |
| Chaincode scripts (list/query/invoke) | ✅    | ✅        | ✅     | ❔          |                      |
| Commands: install / upgrade       | ✅        | ✅        | ✅     | ❔          |                      |

---

## Tools

| Feature       | Fabric v2 | Fabric v3 | Tested | Documented | Todo / Issue        |
|---------------|-----------|-----------|--------|-------------|----------------------|
| Fablo REST    | ✅        | ✅        | ✅     | ❔          |                      |
| Explorer      | ✅        | ❌        | ✅     | ❔          |                      |

---

## Fablo Commands

| Feature                                                                 | Fabric v2 | Fabric v3 | Tested | Documented | Todo / Issue                                                                 |
|-------------------------------------------------------------------------|-----------|-----------|--------|----------|------------------------------------------------------------------------------|
| `generate`                                                              |    ✅     |    ✅     |   ✅   |     ✅     |                                                                              |
| `up`, `start`, `stop`, `down`, `reset`, `recreate`                      |    ✅     |    ✅     |   ✅   |     ✅     |                                                                              |
| `validate`, `extend-config`                                             |    ✅     |    ✅     |   ✅   |     ✅     |                                                                              |
| `version`                                                               |    ✅     |    ✅     |   ✅   |     ✅     |                                                                              |
| `init` (node, rest, dev)                                                |    ✅     |    ✅     |   ✅   |     ✅     |                                                                              |
| Other `init` options                                                    |    ❔     |    ❔     |   ❔   |     ❔     | [Add CLI options to init command](https://github.com/hyperledger-labs/fablo/issues/444) |

---

## Snapshot

| Feature               | Fabric v2 | Fabric v3 | Tested | Documented | Todo / Issue        |
|------------------------|-----------|-----------|--------|-------------|----------------------|
| Create snapshot        | ✅        | ✅        | ✅     | ✅          |                      |
| Restore snapshot       | ✅        | ✅        | ✅     | ✅          |                      |
| Post-start hook        | ❔        | ❔        | ❔     | ❔          | [Add post-start hooks](https://github.com/hyperledger-labs/fablo/issues/111)           |

---

## Other Features

| Feature                | Fabric v2 | Fabric v3 | Tested | Documented | Todo / Issue        |
|------------------------|-----------|-----------|--------|-------------|----------------------|
| Peer dev mode          |✅         |❌         |  ❌    |✅           |[Support dev mode for Fabric v3](https://github.com/hyperledger-labs/fablo/issues/472)                      |
| Connection profiles    |✅         |✅         |✅      |✅           |                      |
| Gateway client         | ❔        | ❔        | ❔     | ❔          |[Adds gateway option to init](https://github.com/hyperledger-labs/fablo/pull/544)                      |
| Hooks: post-generate   |✅         |✅         |✅      |✅           |                      |
| JSON/YAML support      |✅         |✅         |✅      |✅           |                      |