---
layout: home
title: Home
---

## Why Fablo?

Setting up a Hyperledger Fabric network by hand means writing dozens of crypto,
`configtx`, and Docker Compose files. Fablo replaces all of that with a **single
declarative config**: describe the organizations, channels, and chaincodes you
want, and Fablo generates the network and the scripts to operate it on Docker —
with TLS, RAFT/BFT ordering, CouchDB or LevelDB, private data,
chaincode-as-a-service, [Fablo REST](https://github.com/fablo-io/fablo-rest), and
optional Blockchain Explorer (Fabric v2).

Fablo is built for **local development and CI**: spin a full network up in
seconds, run your chaincode and integration tests against it, and tear it down —
repeatably, on any machine with Docker.

For Fabric version compatibility (Explorer, BFT, peer dev mode, and more), see
[SUPPORTED_FEATURES.md](https://github.com/hyperledger-labs/fablo/blob/main/SUPPORTED_FEATURES.md).
