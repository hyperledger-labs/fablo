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

## Managing the network

### init

```bash
fablo init [node] [rest] [dev] [gateway]
```

Creates a simple network configuration file (`fablo-config.json`) in the current directory.
This is a good starting point for your Fablo journey or to set up a quick prototype. 

The generated network configuration includes an orderer organization with two BFT orderer nodes and a peer organization with two peers.
It uses Fabric version `3.1.0`. 

The `fablo init` command accepts several optional parameters (order doesn't matter):
* `node` - generates a sample Node.js chaincode
* `rest` - enables a simple REST API with [Fablo REST](https://github.com/fablo-io/fablo-rest) as a standalone Docker container
* `dev` - enables chaincode hot reload mode
* `gateway` - generates a sample Node.js server that connects to the gateway

Sample command:

```bash
fablo init node dev
```

### generate

```bash
fablo generate [/path/to/fablo-config.json|yaml [/path/to/fablo/target]]
```

Generates network configuration files in the specified directory.
Default config file path is `$(pwd)/fablo-config.json` or `$(pwd)/fablo-config.yaml`, default directory is `$(pwd)/fablo-target`.
If you specify a different directory, you lose Fablo support for other commands.

If you want to use Fablo only to generate the Hyperledger Fabric network configuration, you can provide a target directory parameter or copy the generated `fablo-target` directory content to your desired directory and add it to version control.
Note that generated files may contain variables with paths on your disk and generated crypto material for Hyperledger Fabric.
Review the files before committing to version control.

### up

```bash
fablo up [/path/to/fablo-config.json|yaml]
```

Starts the Hyperledger Fabric network for the given Fablo configuration file, creates channels, and installs and instantiates chaincodes.
If no configuration exists, it will call the `generate` command for the given config file.

### down, start, stop

```bash
fablo [down | start | stop]
```

Stops, starts, or stops the Hyperledger Fabric network for the configuration in the current directory.
This is similar to the down, start, and stop commands for Docker Compose.

### prune

```bash
fablo prune
```

Stops the network and removes the `fablo-target` directory.

### reset and recreate

```bash
fablo reset
fablo recreate [/path/to/fablo-config.json|yaml]
```

* `reset` - combines down and up steps. Network state is lost, but the configuration is kept intact. Useful when you want a fresh network instance without any state.
* `recreate` - prunes the network, generates new config files, and starts the network. Useful when you've edited the `fablo-config` file and want to start a newer network version in one command.    

### validate

```bash
fablo validate [/path/to/fablo-config.json|yaml]
```

Validates the network configuration. This command will validate your network config and suggest necessary changes or additional tweaks.
Note that this step is also executed automatically before each `generate` to ensure that at least critical errors are fixed. 

### export-network-topology

```bash
fablo export-network-topology [/path/to/fablo-config.json] [outputFile.mmd]

```
- `outputFile.mmd`: (optional) Path to the output Mermaid file. Defaults to `network-topology.mmd`.

Sample command:

```bash
fablo export-network-topology fablo-config.json network-topology.mmd
```

You can visualize the output using any Mermaid-compatible tool or online editor.

### extend-config 

```bash
fablo extend-config [/path/to/fablo-config.json|yaml]
```

Generates an extended version of the Fablo config by filling in default and computed values based on the provided configuration file and making some config parts more verbos. 

### snapshot and restore

Fablo supports saving state snapshots (backups) of the network and restoring them.
It saves all network artifacts, certificates, and data from CA, orderer, and peer nodes.
Note that the snapshot does not contain the Fablo config file and chaincode source code, as both can be located outside the Fablo working directory.

Snapshotting is useful if you want to preserve the current state of a network for future use (testing, sharing the network state, courses, etc.).

```bash
fablo snapshot <target-snapshot-path>
```

To restore a snapshot into the current directory, run:

```bash
fablo restore <source-snapshot-path>
```

Example:

1. Assume you have a working network with some state.
2. Run `./fablo snapshot /tmp/my-snapshot`. This creates a file `/tmp/my-snapshot.fablo.tar.gz` with the network state. You don't need to stop the network before making a snapshot.
3. Run `./fablo prune` to destroy the current network. If the network is present, Fablo won't be able to restore the new one from backup.
4. Run `./fablo restore /tmp/my-snapshot` to restore the network.
5. Run `./fablo start` to start the restored network.
6. When running external chaincodes (CCAAS), run `./fablo chaincodes install` to start the CCAAS container

Typically, a snapshot of a network with little data will be less than 1 MB, making it easy to share.

### fabric-docker.sh

The `fabric-docker.sh` script is generated alongside the Docker network configuration.
It doesn't support the `generate` command, but other commands work the same way as in `fablo`.
Essentially, `fablo` forwards some commands to this script.

If you want to use Fablo for network configuration setup only, the `fabric-docker.sh` file allows you to manage the network.

## Managing chaincodes

### chaincode(s) install

```bash
fablo chaincodes install
```
Installs all chaincodes. This might be useful if Fablo fails to install them automatically.

To install a single chaincode defined in the Fablo config file, run:

```bash
fablo chaincode install <chaincode-name> <version>
```

### chaincode upgrade

```bash
fablo chaincode upgrade <chaincode-name> <version>
```

Upgrades the chaincode with the given name on all relevant peers.
The chaincode directory is specified in the Fablo config file.

### chaincode invoke
Invokes a chaincode with the specified parameters.

```
fablo chaincode invoke <peers-domains-comma-separated>  <channel-name>  <chaincode-name> <command> [transient] 
```
Sample command:

```
fablo chaincode invoke "peer0.org1.example.com" "my-channel1" "chaincode1" '{"Args":["KVContract:put", "name", "Willy Wonka"]}'
```

### chaincodes list
Lists the instantiated or installed chaincodes in the specified channel or peer. 

```
fablo chaincodes list <peer> <channel>
```

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


## Channel scripts

### channel help

```bash
fablo channel --help
```
Use it to list all available channel commands.
Commands are generated using fablo-config.json to cover all cases (queries for each channel, organization, and peer).

### channel list
 
```bash
fablo channel list org1 peer0
```
Lists all channels for the given peer.

### channel getinfo

```bash
fablo channel getinfo channel_name org1 peer0
```
Prints channel info, such as current block height for the given peer

### channel fetch config

```bash
fablo channel fetch config channel_name org1 peer0 [file_name.json]
```

Fetches the latest config block, decodes it, and writes it to a JSON file.

### channel fetch raw block

```bash
fablo channel fetch <oldest|newest|block-number> channel_name org1 peer0 [file_name.json]
```
Fetches the oldest, newest, or a block with the given number, and writes it to a file.

## Utility commands

### version

```bash
fablo version [--verbose | -v]
```
Prints the current Fablo version.
With the optional `-v` or `--verbose` flag, it also prints supported Fablo and Hyperledger Fabric versions.

### use

```bash
fablo use
```   

Lists all available Fablo versions.

### use <version-number>

```bash
fablo use <version-number>
```   

Switches the current script to the selected version.

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

