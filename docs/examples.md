---
layout: doc
title: Examples
---

<div class="examples-page" markdown="1">

# Explore Fablo by example

Start with a small local network, then add collaboration, data privacy, external chaincode services, operational tools, and repeatable state. Every example below maps to a maintained sample or documented command.
{: .examples-lede }

<ul class="example-index">
  <li><a href="#first-network">Your first network</a></li>
  <li><a href="#private-data">Private data across organizations</a></li>
  <li><a href="#ccaas-rest">CCaaS, CouchDB, and REST</a></li>
  <li><a href="#explorer">Blockchain Explorer for Fabric v2</a></li>
  <li><a href="#snapshot-restore">Snapshot and restore</a></li>
</ul>

<section class="example-feature" id="first-network" markdown="1">

## Start with one local network

Scaffold a Fabric 3.1 network and a sample Node.js chaincode, inspect the generated Docker files, then start everything with one command.
{: .example-summary }

<div class="example-meta"><span>Fabric 3.1</span><span>TLS</span><span>BFT</span><span>Node.js chaincode</span></div>

### Try it

```bash
mkdir fablo-first-network && cd fablo-first-network
fablo init node
fablo generate
fablo up
```

`fablo init node` creates `fablo-config.json` plus a sample chaincode. `generate` writes the network artifacts to `fablo-target`, and `up` starts the network, creates its channel, and deploys the chaincode.

<figure class="example-output">
  <img src="/assets/examples/generated-network.svg" width="1040" height="500" loading="lazy" alt="Terminal output showing the main configuration, Docker, connection profile, chaincode script, and topology files generated in fablo-target.">
  <figcaption>Representative generated files. The exact organization-specific files follow the organizations in your config.</figcaption>
</figure>

<div class="example-links">
  <a href="/getting-started.html">Follow the full guide &rarr;</a>
  <a href="https://github.com/hyperledger-labs/fablo/blob/main/samples/fablo-config-hlf3-1orgs-2chaincodes.json">Open a Fabric 3 sample &rarr;</a>
</div>

</section>

<section class="example-feature" id="private-data" markdown="1">

## Share a channel, keep selected data private

Model two peer organizations on one channel, set explicit endorsement policies, and give each chaincode the private collections it needs.
{: .example-summary }

<div class="example-meta"><span>Fabric 2.5</span><span>2 organizations</span><span>endorsement policies</span><span>private data</span></div>

### Configuration excerpt

```yaml
chaincodes:
  - name: or-policy-chaincode
    version: 0.0.1
    lang: node
    channel: my-channel1
    directory: ./chaincodes/chaincode-kv-node
    endorsement: OR('Org1MSP.member', 'Org2MSP.member')
    privateData:
      - name: org1-collection
        orgNames: [Org1]
```

Generate the network normally with `fablo up`. Fablo writes the collection configuration and uses the declared policy when the chaincode is deployed.

<figure class="example-output">
  <img src="/assets/examples/private-data-topology.svg" width="1040" height="520" loading="lazy" alt="Network topology showing Org1 and Org2 peers connected to my-channel1, with one Org1-only collection and one collection shared by both organizations.">
  <figcaption>The sample combines an organization-only collection with a second collection available to both peer organizations.</figcaption>
</figure>

<div class="example-links">
  <a href="https://github.com/hyperledger-labs/fablo/blob/main/samples/fablo-config-hlf2-2orgs-2chaincodes-private-data.yaml">View the complete sample &rarr;</a>
  <a href="/reference/configuration.html#chaincodesprivatedata">Private data reference &rarr;</a>
</div>

</section>

<section class="example-feature" id="ccaas-rest" markdown="1">

## Run chaincode as a service

Use a container image for CCaaS, store world state in CouchDB, and expose Fabric operations through Fablo REST for each peer organization.
{: .example-summary }

<div class="example-meta"><span>Fabric 3.1</span><span>CCaaS</span><span>CouchDB</span><span>Fablo REST</span></div>

### Configuration excerpt

```yaml
orgs:
  - organization: { name: Org1, domain: org1.example.com }
    peer: { instances: 1, db: CouchDb }
    tools: { fabloRest: true }
chaincodes:
  - name: chaincode1
    version: 0.0.1
    lang: ccaas
    channel: my-channel1
    image: ghcr.io/fablo-io/fablo-sample-kv-node-chaincode:2.2.0
    chaincodeStartCommand: npm run start:ccaas
```

The complete sample applies the peer and tool settings to both organizations and connects them through `my-channel1`.

<figure class="example-output">
  <img src="/assets/examples/ccaas-services.svg" width="1040" height="500" loading="lazy" alt="Terminal output listing running peers, CouchDB databases, Fablo REST services, and a chaincode-as-a-service container.">
  <figcaption>Representative service groups after startup. Docker Compose service names can vary with the generated network.</figcaption>
</figure>

<div class="example-links">
  <a href="https://github.com/hyperledger-labs/fablo/blob/main/samples/fablo-config-hlf3-2orgs-1chaincode-raft-ccaas.json">View the complete sample &rarr;</a>
  <a href="/reference/configuration.html#chaincodes">Chaincode reference &rarr;</a>
  <a href="https://github.com/fablo-io/fablo-rest">Explore Fablo REST &rarr;</a>
</div>

</section>

<section class="example-feature" id="explorer" markdown="1">

## Add Blockchain Explorer to Fabric v2

Enable the optional Explorer UI when you need to inspect channels, blocks, and transactions in a Fabric 2.5 development network.
{: .example-summary }

<div class="example-meta"><span>Fabric 2.5 only</span><span>Explorer</span><span>TLS</span><span>RAFT</span></div>

### Configuration excerpt

```json
{
  "global": {
    "fabricVersion": "2.5.12",
    "tls": true,
    "tools": { "explorer": true }
  }
}
```

Explorer is supported for Fabric v2 and not Fabric v3. Keep the Fabric version explicit, then run `fablo up` to generate its connection material and start its containers with the network.

<figure class="example-output">
  <img src="/assets/examples/explorer-services.svg" width="1040" height="460" loading="lazy" alt="Terminal output showing generated Blockchain Explorer configuration and connection profile files for a Fabric version 2 network.">
  <figcaption>Fablo generates Explorer configuration and connection-profile material from the same network declaration.</figcaption>
</figure>

<div class="example-links">
  <a href="https://github.com/hyperledger-labs/fablo/blob/main/samples/fablo-config-hlf2-3orgs-1chaincode-raft-explorer.json">View the Explorer sample &rarr;</a>
  <a href="https://github.com/hyperledger-labs/fablo/blob/main/SUPPORTED_FEATURES.md">Check feature compatibility &rarr;</a>
</div>

</section>

<section class="example-feature" id="snapshot-restore" markdown="1">

## Save state before the next experiment

Capture a complete local network state, including transactions and identities, then restore it after a test, upgrade, or destructive change.
{: .example-summary }

<div class="example-meta"><span>Fabric 2.5 and 3.1</span><span>network state</span><span>repeatable testing</span></div>

### Try it

```bash
fablo snapshot ./snapshots/before-upgrade
fablo down
fablo restore ./snapshots/before-upgrade
```

Use a snapshot path outside `fablo-target` if you plan to prune generated files before restoring the network.

<figure class="example-output">
  <img src="/assets/examples/snapshot-restore.svg" width="1040" height="430" loading="lazy" alt="Terminal workflow running fablo snapshot, fablo down, and fablo restore against a named local snapshot.">
  <figcaption>A compact snapshot workflow for repeatable integration tests and local upgrade experiments.</figcaption>
</figure>

<div class="example-links">
  <a href="/reference/cli-commands.html#snapshot-commands">Snapshot command reference &rarr;</a>
  <a href="https://github.com/hyperledger-labs/fablo/blob/main/e2e-network/docker/test-04-v3-snapshot-ccaas.sh">See the tested workflow &rarr;</a>
</div>

</section>

<aside class="examples-next" markdown="1">

## Build your own variation

Start from the closest sample, then use the [configuration reference](/reference/configuration.html) to change organizations, channels, databases, orderers, and chaincodes. Run `fablo validate` before generating the network, or edit a valid config in the [browser-based Config editor](/editor.html).

</aside>

</div>
