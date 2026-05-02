# Fabric-X Support in Fablo (POC)

> **Status**: Proof of Concept — ~50% functional prototype  
> **Author**: [@zyzzmohit](https://github.com/zyzzmohit)  
> **Related Mentorship**: [LFDT - Fablo: Add support for Fabric-X](https://mentorship.lfx.linuxfoundation.org)

## What is Fabric-X?

Hyperledger Fabric-X is a next-generation architecture for Hyperledger Fabric, designed for **digital asset use cases**. It decomposes the monolithic peer and orderer into independently scalable microservices:

### Architecture Comparison

```
Classic Fabric:          Fabric-X:
┌─────────┐             ┌─────────────────────────────────┐
│  Peer   │             │ ORDERER PIPELINE (Arma BFT)     │
│ (mono)  │             │ Router → Batcher → Consenter    │
└─────────┘             │    → Assembler                  │
┌─────────┐             ├─────────────────────────────────┤
│ Orderer │             │ COMMITTER STACK                 │
│ (Raft)  │             │ Sidecar → Coordinator           │
└─────────┘             │    → Validator-Committer        │
                        │    → Verification Service       │
                        │    → Query Service              │
                        └─────────────────────────────────┘
```

### Key Differences

| Feature | Classic Fabric | Fabric-X |
|---|---|---|
| Consensus | Raft / BFT | Arma BFT (sharded, high-throughput) |
| Peer | Monolithic | Decomposed microservices |
| Programming | Chaincode (Go/Node/Java) | fabric-smart-client + token-sdk |
| Channels | Multi-channel | Single channel with namespaces |
| Deployment | Docker Compose (Fablo) | Ansible scripts |

## Using Fabric-X with Fablo

### Quick Start

```bash
# Generate a Fabric-X config
fablo init fabric-x

# Validate the config
fablo validate

# Generate Docker Compose files
fablo generate
```

### Configuration

The Fabric-X config uses the `engine: "fabric-x"` setting and adds a `global.fabricX` section:

```json
{
  "global": {
    "engine": "fabric-x",
    "fabricX": {
      "version": "0.0.15",
      "orderer": {
        "routerInstances": 1,
        "batcherShards": 1,
        "batchersPerShard": 1,
        "consenterInstances": 1,
        "assemblerInstances": 1
      },
      "committer": {
        "instances": 1
      }
    }
  }
}
```

### Orderer Components

- **Router** (`routerInstances`): Accepts client transactions and dispatches to batchers
- **Batcher** (`batcherShards` × `batchersPerShard`): Groups transactions into batches, supports sharding for throughput
- **Consenter** (`consenterInstances`): Runs Arma BFT consensus on batch attestations
- **Assembler** (`assemblerInstances`): Creates the ordered ledger of blocks

### Committer Components

Each committer instance is a stack of 5 microservices:
- **Sidecar**: Middleware between orderer pipeline and coordinator
- **Coordinator**: Orchestrates the validation pipeline
- **Validator-Committer**: Optimistic concurrency control + commit to ledger
- **Verification Service**: Signature validation against endorsement policies
- **Query Service**: Read-only state access

## Docker Images

This POC uses pre-built images from GHCR:

| Component | Image |
|---|---|
| Orderer components | `ghcr.io/hyperledger/fabric-x-orderer` |
| Committer components | `ghcr.io/hyperledger/fabric-x-committer` |
| CLI tools | `ghcr.io/hyperledger/fabric-x-tools` |
| Load generator | `ghcr.io/hyperledger/fabric-x-loadgen` |

### Fallback: Build from Source

If pre-built images are not available for your version:

```bash
# Clone and build
git clone https://github.com/hyperledger/fabric-x-orderer
cd fabric-x-orderer && docker build -t fabric-x-orderer:local .

git clone https://github.com/hyperledger/fabric-x-committer
cd fabric-x-committer && docker build -t fabric-x-committer:local .
```

Then update image references in the generated `.env` file.

## Current Limitations

This is a POC demonstrating the integration path. The following are not yet implemented:

- ❌ TLS configuration for Fabric-X components
- ❌ Chaincode/smart-contract deployment (Fabric-X uses different programming model)
- ❌ Multi-org topology
- ❌ `fablo up` / `fablo down` lifecycle integration
- ❌ Network topology diagram for Fabric-X
- ❌ Grafana/Prometheus monitoring stack

## Architecture Decision: Why Pluggable Engine?

We chose the **pluggable engine approach** (`engine: "fabric-x"`) over:
- **Separate repo**: Would fragment the Fablo ecosystem
- **Wrapper approach**: Too loosely coupled, hard to maintain

The engine approach:
- ✅ Stays within the Fablo repo
- ✅ Reuses existing CLI infrastructure
- ✅ Shares validation, config parsing, and template rendering
- ✅ Clean separation via engine-specific code paths
- ✅ Aligns with existing `engine: "docker" | "kubernetes"` pattern
