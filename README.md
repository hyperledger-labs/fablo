![Github Actions](https://github.com/hyperledger-labs/fablo/actions/workflows/test.yml/badge.svg?branch=main)

<h1><img src="./logo.svg" alt="Fablo"/></h1>

Fablo allows you to start Hyperledger Fabric network from a single config file. It's best for local development, CI processes and experimenting with various network configurations.

Fablo supports:

* Environment: Docker
* RAFT, solo and BFT consensus protocols
* Multiple organizations and channels
* Chaincode installation and upgrade (Node, Go, Java, CCaaS)
* REST API client for CA and chaincodes ([Fablo REST](https://github.com/fablo-io/fablo-rest))
* [Blockchain Explorer](https://github.com/hyperledger/blockchain-explorer) which can be enabled for each organization

Visit [SUPPORTED_FEATURES.md](SUPPORTED_FEATURES.md) to see the full list of features supported by Fablo.

## See it in action

[&gt;&gt;&gt; Watch the demo &lt;&lt;&lt;](https://www.youtube.com/watch?v=5yn3_g6Cybw)

## Quick start

```bash
curl fablo.io/install.sh | bash
./fablo init node rest
./fablo up
```

This will create a local Hyperledger Fabric network with a sample Node.js chaincode (using the `node` parameter) and a REST API client (using the `rest` parameter).
After a few minutes, the entire network will be set up and running.

You can check the running nodes using `docker ps` or `docker stats`. You can also query the network via the command line (`fablo chaincode invoke` or `fablo chaincode query`), use the REST API client (see [Fablo REST](https://github.com/fablo-io/fablo-rest)), or view the network topology in the `fablo-target/network-topology.mmd` Mermaid diagram.

## Installation

Fablo is distributed as a single shell script that uses a Docker image to generate the network configuration.
To install it locally in your project directory:

```bash
curl fablo.io/install.sh | bash
# OR
curl fablo.io/fablo.sh > fablo && chmod +x fablo
```

To install it globally on your system:

```bash
sudo curl fablo.io/fablo.sh -o /usr/local/bin/fablo && sudo chmod +x /usr/local/bin/fablo
```

To install a given version use:

```bash
curl https://github.com/hyperledger-labs/fablo/releases/download/<version>/fablo.sh
```

To change version of current installation:

```bash
fablo use <version>
```

Note: If you install Fablo as a local script, you call it as `./fablo <command>`.
If you install it globally, you call `fablo <command>`.
For the simplicity we will refer to it as `fablo`.


## Basic usage

```bash
fablo up /path/to/fablo-config.json
```

The `up` command creates the initial configuration and starts the Hyperledger Fabric network on Docker.
The network configuration is saved in `$(pwd)/fablo-target`.
You can then manage the network with other commands such as `stop`, `start`, `down`, and `prune`.

The Fablo configuration file describes the network topology: root organization, other organizations, channels, and chaincodes.
See the [samples](https://github.com/hyperledger-labs/fablo/blob/main/samples/) or [Fablo config](https://github.com/hyperledger-labs/fablo#fablo-config) section for examples.

There are two basic use cases.
You may use Fablo to start and manage the network for development purposes, test different network topologies, run it in CI environment etc.
In this case you should keep `fablo-target` directory intact and out of the version control.
Fablo will manage it locally.

On the other hand you can use Fablo to generate initial network configuration, keep it in version control and tweak for specific requirements.
In this case, however, you should use generated `fablo-docker.sh` instead of `fablo` script.

## Command guides

Fablo command documentation has been split into focused pages for easier onboarding and maintenance.

### Start here

- [docs/commands/README.md](docs/commands/README.md)

### Network setup and lifecycle

- [init](docs/commands/init.md)
- [generate](docs/commands/generate.md)
- [up](docs/commands/up.md)
- [down, start, stop](docs/commands/down-start-stop.md)
- [prune, reset, recreate](docs/commands/prune-reset-recreate.md)
- [snapshot and restore](docs/commands/snapshot-restore.md)

### Config and diagnostics

- [validate](docs/commands/validate.md)
- [extend-config](docs/commands/extend-config.md)
- [export-network-topology](docs/commands/export-network-topology.md)

### Chaincode and channel operations

- [chaincode commands](docs/commands/chaincode.md)
- [channel commands](docs/commands/channel.md)

### Utility commands

- [version and use](docs/commands/version-use.md)

### fabric-docker.sh

The `fabric-docker.sh` script is generated alongside Docker network configuration.
It does not support `generate`, but other lifecycle commands mirror `fablo` behavior.

### Achieving chaincode hot reload

Hot reload of chaincode code is a way to speed up development.
In this case, chaincodes don't need to be upgraded each time, but they are run locally.

Fablo supports two options for achieving hot code reload in chaincodes:
1. Using Hyperledger Fabric [peer dev mode](https://hyperledger-fabric.readthedocs.io/en/release-2.4/peer-chaincode-devmode.html)
2. Using CCaaS chaincode type with the chaincode process running inside the container

The peer dev mode approach is simpler but has some trade-offs.

| Peer dev mode | CCaaS |
|---------------|-------|
| You run the chaincode process locally (simpler setup) | Fablo runs the process in CCaaS container with chaincode volume mounted |
| non-TLS only | supports TLS |
| global per network | set for individual chaincodes |

#### Peer dev mode

The simplest way to try Fablo with dev mode is as follows:

1. Ensure you have `global.peerDevMode` set to `true` and `global.tls` set to `false` in `fablo-config.json`.
2. Start the network with `fablo up`.
   Because dev mode is enabled, chaincode containers don't start.
   Instead, Fablo approves and commits chaincode definitions from the Fablo config file.
3. Start the chaincode process locally.
   Note: If you have multiple peers you want to use, you need to start a separate chaincode process for each peer.

**For Node.js chaincode:**

Install npm dependencies and start the sample chaincode with:
   ```bash
   (cd chaincodes/chaincode-kv-node && nvm use && npm i && npm run start:watch)
   ```
   Now, when you update the chaincode source code, it will be automatically refreshed on the Hyperledger Fabric network.

The relevant scripts in `package.json` look like:

```json
  "scripts": {
    ...
    "start:dev": "fabric-chaincode-node start --peer.address \"127.0.0.1:8541\" --chaincode-id-name \"chaincode1:0.0.1\" --tls.enabled false",
    "start:watch": "nodemon --exec \"npm run start:dev\"",
    ...
  },
```

**For Java Chaincode:**

Build and run the Java chaincode locally. As a sample, you can use the chaincode from the Fablo source code in the `samples/chaincodes/java-chaincode` directory. Ensure a proper relative path is provided in the Fablo config.

```bash
cd samples/chaincodes/java-chaincode
./run-dev.sh
```

The `run-dev.sh` script will:
- Build the chaincode using Gradle's shadowJar task
- Automatically detect the peer's IP address from the Docker container
- Start the chaincode with debug logging enabled
- Connect to the peer at port 7051

For local development and review:
- The chaincode will run with the name `simple-asset:1.0`
- Debug level logging is enabled via `CORE_CHAINCODE_LOGLEVEL=debug`
- You can modify the Java code and rebuild/restart to see changes
- The peer connection is automatically configured using the Docker container's IP

### CCaaS to achieve chaincode hot reload

To achieve hot reload for both TLS and non-TLS setups, use the CCaaS feature in combination with `chaincodeMountPath` and `chaincodeStartCommand` parameters.
This way, you can start chaincode processes in CCaaS containers while having chaincode source code mounted, and reload when the code changes.

This approach has several benefits:
* It works for both TLS and non-TLS
* You can have only some chaincodes running in hot reload mode while others run in regular containers
* Fablo manages starting chaincode processes

You can initialize a network with a sample setup by running the `fablo init` command:

```
fablo init dev node
```

This produces the following chaincode configuration:

```json
  "chaincodes": [
    {
      "name": "chaincode1",
      "version": "0.0.1",
      "channel": "my-channel1",
      "lang": "ccaas",
      "image": "hyperledger/fabric-nodeenv:${FABRIC_NODEENV_VERSION:-2.5}",
      "chaincodeMountPath": "$CHAINCODES_BASE_DIR/chaincodes/chaincode-kv-node",
      "chaincodeStartCommand": "npm run start:watch:ccaas",
      "privateData": []
    }
  ],
  "hooks": {
    "postGenerate": "npm i --prefix ./chaincodes/chaincode-kv-node"
  }
```

You can find a full end-to-end example in one of our test scripts [test-01-v3-simple.sh](e2e-network/docker/test-01-v3-simple.sh).


For detailed channel and utility command references, use the command guides in [docs/commands/README.md](docs/commands/README.md).

## Fablo config

The Fablo config is a single JSON or YAML file that describes the desired Hyperledger Fabric network topology (network settings, CA, orderer, organizations, peers, channels, chaincodes).
It must be compatible with the [schema].
You can generate a basic config with the `./fablo init` command.
See the [samples](https://github.com/hyperledger-labs/fablo/blob/main/samples/) directory for more complex examples.

The basic structure of Fablo config file is as follows:

```json
{
  "$schema": "https://github.com/hyperledger-labs/fablo/releases/download/2.5.0/schema.json",
  "global": { ... },
  "orgs": [ ... ],
  "channels": [ ... ],
  "chaincodes": [ ... ]
}
```

### global

Example:

```json
  "global": {
    "fabricVersion": "2.4.2",
    "tls": false,
    "peerDevMode": false,
    "monitoring": {
      "loglevel": "debug"
    },
    "tools": {
      "explorer": false
    }
  },
```

### global.fabricImages

`global.fabricImages` is optional
Example:

```json
"fabricImages": {
  "peer": "ghcr.io/fabric-dev/fabric-peer:3.1.0",
  "orderer": "ghcr.io/fabric-dev/fabric-orderer:3.1.0",
  "tools": "ghcr.io/fablo-io/fabric-tools:3.0.0"
}
```

For Fabric `3.x`, the default `tools` image repository is `ghcr.io/fablo-io/fabric-tools`; for older versions it is `hyperledger/fabric-tools`.

### orgs

Example:

```json
  "orgs": [
    {
      "organization": {
        "name": "Org1",
        "domain": "org1.example.com"
      },
      "peer": {
        "instances": 2,
        "db": "LevelDb"
      },
      "orderers": [{
        "groupName": "group1",
        "type": "raft",
        "instances": 3
      }],
      "tools": {
        "fabloRest": true,
        "explorer": true
      }
    },
    ...
  ],
```

Other available parameters for entries in the `orgs` array are:

 * `organization.mspName` (default: `organization.name + 'MSP'`)
 * `ca.prefix` (default: `ca`)
 * `ca.db` (default: `sqlite`, other: `postgres`)
 * `peer.prefix` (default: `peer`)
 * `peer.anchorPeerInstances` (default: `1`)
 * `orderers` (defaults to empty: `[]`)
 * `tools.explorer` - whether to run Blockchain Explorer for the organization (default: `false`)
 * `tools.fabloRest` - whether to run Fablo REST for the organization (default: `false`)
 
### property `peer.db`:
- Can be `LevelDb` (default) or `CouchDb`.  

### property `orderers`:
- Is optional as some organizations may have orderers defined, but others don't.
- At least one orderer group is required to run the Fabric network (requirement is validated before run).
- If you want to spread orderers in a group between many organizations, use the same `groupName` in every group definition.
- The property `orderers.type` can be `solo` or `raft`. We do not support the Kafka orderer.

### channels

Example:

```json
  "channels": [
    {
      "name": "my-channel1",
      "groupName": "group1",      
      "orgs": [
        {
          "name": "Org1",
          "peers": [
            "peer0",
            "peer1"
          ]
        },
        {
          "name": "Org2",
          "peers": [
            "peer0"
          ]
        }
      ]
    },
    ...
  ],
```

- Property `groupName` is optional (defaults to the first orderer group found). If you want to handle a channel with a different orderer group, define it in `orgs` and pass its name here. 

### chaincodes

Example:

```json
  "chaincodes": [
    {
      "name": "chaincode1",
      "version": "0.0.1",
      "lang": "node",
      "channel": "my-channel1",
      "directory": "./chaincodes/chaincode-kv-node",
      "privateData": {
        "name": "org1-collection",
        "orgNames": ["Org1"]
      }
    },
    {
      "name": "chaincode2",
      "version": "0.0.1",
      "lang": "java",
      "channel": "my-channel2"
    }
  ]
```

The property `lang` can be `golang`, `java`, `node`, or `ccaas`.

The `privateData` parameter is optional. You don't need to define the private data collection for the chaincode. By default, there is none (just the implicit private data collection which is default in Fabric).

Other available parameters for entries in the `chaincodes` array are:

* `init` - initialization arguments (for Hyperledger Fabric below 2.0; default: `{"Args":[]}`)
* `initRequired` - whether the chaincode requires an initialization transaction (for Hyperledger Fabric 2.0 and greater; default: `false`)
* `endorsement` - the endorsement policy for the chaincode (if missing for Hyperledger Fabric 2.0 and greater, there is no default value - Hyperledger by default will take the majority of organizations)
* `chaincodeMountPath` (`ccaas` only) - chaincode mount path. If provided, the given directory is mounted inside the Docker container and becomes the container working directory.
* `chaincodeStartCommand` (`ccaas` only) - chaincode start command. If provided, this command is used as the Docker container command.



### hooks

Hooks in Fablo are Bash commands to be executed after specific events.
Supported hooks:

- `postGenerate` — executed after the network config is generated (after `./fablo generate`, executed separately or automatically by `./fablo up`).
- `postStart` — executed after the network is started (after `./fablo up` or `./fablo start`).

Example `postGenerate` hook that changes `MaxMessageCount` to 1 in generated Hyperledger Fabric config:

```json
  "hooks": {
    "postGenerate": "perl -i -pe 's/MaxMessageCount: 10/MaxMessageCount: 1/g' \"./fablo-target/fabric-config/configtx.yaml\""
  }
```

Example `postStart` hook that waits for peers to be ready or performs any additional bootstrap actions:

```json
  "hooks": {
    "postStart": "echo 'Network started' && ./fablo-target/fabric-docker.sh channel list org1 peer0"
  }
```

Generated hooks are saved in `fablo-target/hooks`.


### Sample YAML config file

```yaml
---
"$schema": https://github.com/hyperledger-labs/fablo/releases/download/2.5.0/schema.json
global:
  fabricVersion: 2.4.2
  tls: false
orgs:
  - organization:
      name: Orderer
      domain: root.com
    orderers:
      - groupName: group1
        prefix: orderer
        type: solo
        instances: 1 
  - organization:
      name: Org1
      domain: org1.example.com
      tools:
        fabloRest: true
        explorer: true
    peer:
      instances: 2
  - organization:
      name: Org2
      domain: org2.example.com
    peer:
      instances: 1
channels:
  - name: my-channel1
    orgs:
      - name: Org1
        peers:
          - peer0
          - peer1
      - name: Org2
        peers:
          - peer0
chaincodes:
  - name: and-policy-chaincode
    version: 0.0.1
    lang: node
    channel: my-channel1
    init: '{"Args":[]}'
    endorsement: AND('Org1MSP.member', 'Org2MSP.member')
    directory: "./chaincodes/chaincode-kv-node"
    privateData:
      - name: org1-collection
        orgNames:
          - Org1
```

## Kubernetes support

TODO

## Other features

### Connection profiles

Fablo will generate connection profiles for each organization defined in the configuration.
You can find them in the `fablo-target/fablo-config/connection-profiles` directory in `json` and `yaml` format.

### REST API

Fablo is integrated with a simple REST API for CA and chaincodes, supported by [Fablo REST](https://github.com/fablo-io/fablo-rest).
To use it, set `"tools": { "fabloRest": true }` for your organization.
Visit the [Fablo REST](https://github.com/fablo-io/fablo-rest) project for more documentation.

### Blockchain Explorer

Fablo can run [Blockchain Explorer](https://github.com/hyperledger/blockchain-explorer) for you.
Set `"tools": { "explorer": true }` for your organization if you want to use it per organization, or set the same value in the `global` section of the config if you want to use one global Explorer for all organizations.

## Contributing

We'd love to have you contribute! Please refer to our [contribution guidelines](https://github.com/hyperledger-labs/fablo/blob/main/CONTRIBUTING.md) for details.

## Testimonials

Fablo was originally created at [SoftwareMill](https://softwaremill.com) by [@Hejwo](https://github.com/Hejwo/) and [@dzikowski](https://github.com/dzikowski/).
In December 2021, Fablo joined [Hyperledger Labs](https://labs.hyperledger.org/).

## Talks
* [Simplifying Fabric Dev: New Features in Fablo](https://www.youtube.com/watch?v=5yn3_g6Cybw) by [@dzikowski](https://github.com/dzikowski), [dpereowei](https://github.com/dpereowei), and [@OsamaRab3](https://github.com/OsamaRab3) (November 2025)
* [Kick-off your Hyperledger Fabric network](https://www.youtube.com/watch?v=JqPNozCtHkQ) by [@Hejwo](https://github.com/Hejwo) (Feburary 2021; Fablo was called "Fabrica" at that time)
