---
layout: home
title: Home
---

## Why Fablo?

Setting up a Hyperledger Fabric network by hand means writing dozens of crypto,
`configtx`, and Docker Compose files. Fablo replaces all of that with a **single
declarative config**: describe the organizations, channels, and chaincodes you
want, and Fablo generates the network and the scripts to operate it on Docker —
with TLS, RAFT/BFT ordering, CouchDB, private data, chaincode-as-a-service, a
REST gateway, and Blockchain Explorer all built in.

Fablo is built for **local development and CI**: spin a full network up in
seconds, run your chaincode and integration tests against it, and tear it down —
repeatably, on any machine with Docker.
