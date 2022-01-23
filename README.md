![Github Actions](https://github.com/hyperledger-labs/fablo/actions/workflows/test.yml/badge.svg?branch=main)

<h1><img src="./logo.svg" alt="Fablo"/></h1>

Fablo supports:

* Environment: Docker
* RAFT and solo consensus protocols
* Multiple organizations and channels
* Chaincode installation and upgrade
* REST API client for CA and chaincodes ([Fablo REST](https://github.com/softwaremill/fablo-rest))
* [Blockchain Explorer](https://github.com/hyperledger/blockchain-explorer) which can be enabled for each organization

## See it in action

[![How to use](https://img.youtube.com/vi/JqPNozCtHkQ/0.jpg)](https://www.youtube.com/watch?v=JqPNozCtHkQ)

## Installation

Fablo is distributed as a single shell script which uses Docker image to generate the network config.
You may keep the script in the root directory of your project or install it globally in your file system.

To install it globally:

```bash
sudo curl -Lf https://github.com/hyperledger-labs/fablo/releases/download/1.0.0/fablo.sh -o /usr/local/bin/fablo && sudo chmod +x /usr/local/bin/fablo
```

To get a copy of Fablo for a single project, execute in the project root:

```bash
curl -Lf https://github.com/hyperledger-labs/fablo/releases/download/1.0.0/fablo.sh -o ./fablo && chmod +x ./fablo
```

## Getting started

To create a local Hyperledger Fabric network with Node.js chaincode and REST API client, install Fablo and execute:

```bash
./fablo init node rest
./fablo up
```

After a few minutes the whole network will be set up and running.
You can check the running nodes via `docker ps` or `docker stats`, and you can query the network with command line (via `cli.org1.example.com` container) or REST API client (via [Fablo REST](https://github.com/softwaremill/fablo-rest)).

## Basic usage

```bash
fablo up /path/to/fablo-config.json
```

The `up` command creates initial configuration and starts Hyperledger Fabric network on Docker.
In this case network configuration is saved in `$(pwd)/fablo-target`.
Then you can manage the network with other commands, for example `stop`, `start`, `down`, `prune`.

Provided Fablo configuration file describes network topology: root organization, other organizations, channels and chaincodes.
See the [samples](https://github.com/hyperledger-labs/fablo/blob/main/samples/) or [Fablo config](https://github.com/hyperledger-labs/fablo#fablo-config) section.

There are two basic use cases.
You may use Fablo to start and manage the network for development purposes, test different network topologies, run it in CI environment etc.
In this case you should keep `fabrika-target` directory intact and out of the version control.
Fablo will manage it locally.

On the other hand you can use Fablo to generate initial network configuration, keep it in version control and tweak for specific requirements.
In this case, however, you should use generated `fablo-docker.sh` instead of `fablo` script.

## Managing the network

### init

```bash
fablo init [node]
```

Creates simple network config file in current dir.
Good step to start your adventure with Fablo or set up a fast prototype. 

Option `node` makes Fablo to generate a sample Node.js chaincode as well.

Generated `fablo-config.json` file uses single node Solo consensus and no TLS support.
This is the simplest way to start with Hyperledger Fabric, since Raft consensus requires TLS and TLS itself adds a lot of complexity to the blockchain network and integration with it.

### generate

```bash
fablo generate [/path/to/fablo-config.json|yaml [/path/to/fablo/target]]
```

Generates network configuration files in the given directory.
Default config file path is `$(pwd)/fablo-config.json` or `\$(pwd)/fablo-config.yaml`, default directory is `$(pwd)/fablo-target`.
If you specify a different directory, you loose Fablo support for other commands.

If you want to use Fablo only to kick off the Hyperledger Fabric network, you may provide target directory parameter or just copy generated Fablo target directory content to desired directory and add it to version control.
Note that generated files may contain variables with paths on your disk and generated crypto material for Hyperledger Fabric.
Review the files before submitting to version control system.

### up

```bash
fablo up [/path/to/fablo-config.json|yaml]
```

Starts the Hyperledger Fabric network for given Fablo configuration file, creates channels, installs and instantiates chaincodes.
If there is no configuration, it will call `generate` command for given config file.

### down, start, stop

```bash
fablo [down | start | stop]
```

Downs, starts or stops the Hyperledger Fabric network for configuration in the current directory.
This is similar to down, start and stop commands for Docker Compose.

### prune

```bash
fablo prune
```

Downs the network and removes `fablo-target` directory.

### reset and recreate

```bash
fablo reset
fablo recreate [/path/to/fablo-config.json|yaml]
```

* `reset` -- down and up steps combined. Network state is lost, but the configuration is kept intact. Useful in cases when you want a fresh instance of network without any state.
* `recreate` -- prunes the network, generates new config files and ups the network. Useful when you edited `fablo-config` file and want to start newer network version in one command.    

### validate

```bash
fablo validate [/path/to/fablo-config.json|yaml]
```

Validates network config. This command will validate your network config try to suggest necessary changes or additional tweaks.
Please note that this step is also executed automatically before each `generate` to ensure that at least critical errors where fixed. 

### snapshot and restore

Fablo supports saving state snapshot (backup) of the network and restoring it.
It saves all network artifacts, certificates, and the data of CA, orderer and peer nodes.
Note the snapshot does not contain Fablo config file and chaincode source code, since both can be located outside Fablo working directory.

Snapshotting might be useful if you want to keep the current state of a network for future use (for testing, sharing the network state, courses and so on).

```bash
fablo snapshot <target-snapshot-path>
```

If you want to restore snapshot into current directory, execute:

```bash
fablo restore <source-snapshot-path>
```

Example:

1. Assume you have a working network with some state.
2. Execute `./fablo shnapshot /tmp/my-snapshot`. It will create a file `/tmp/my-snapshot.fablo.tar.gz` with the state of the network. It is not required to stop the network before making a snapshot.
3. Execute `./fablo prune` to destroy the current network. If the network was present, Fablo would not be able to restore the new one from backup.
4. Execute `./fablo restore /tmp/my-snapshot` to restore the network.
5. Execute `./fablo start` to start the restored network.

Typically, a snapshot of the network with little data will take less than 1 MB, so it is easy to share.

### fabric-docker.sh

The script `fabric-docker.sh` is generated among docker network configuration.
It does not support `generate` command, however other commands work in same way as in `fablo`.
Basically `fablo` forwards some commands to this script.

If you want to use Fablo for network configuration setup only, then the `fabric-docker.sh` file allows you to manage the network.

## Managing chaincodes

### chaincode upgrade

```bash
fablo chaincode upgrade chaincode-name version
```

Upgrades and instantiates chaincode with given name on all relevant peers.
Chaincode directory is specified in Fablo config file.

## Managing channels

### chaincode channel

```bash
fablo channel --help
```
Use it to list all available channel commands.  
Commands are generated using fablo-config.json to cover all cases (queries for each channel. organization and peer)
 
```bash
fablo channel list org1 peer0
```
lists all channels for given peer

```bash
fablo channel getinfo channel_name org1 peer0
```
Prints channel info ei. current block height for given peer

```bash
fablo channel fetch config channel_name org1 peer0 file_name.json
```
Fetches latest config block, decodes it and write to a json file.

```bash
fablo channel fetch lastBlock channel_name org1 peer0 file_name.json
```
Fetches latest block, decodes it and write to a json file. It might be transaction block or config block.

```bash
fablo channel fetch firstBlock channel_name org1 peer0 file_name.json
```
Fetches first block for given channel. Usually it will be initial channel configuration. 

## Utility commands

### version

```bash
fablo version [--verbose | -v]
```
Prints current Fablo version.
With optional `-v` or `--verbose` flag it prints supported Fablo and Hyperledger Fabric versions as well.

### use

```bash
fablo use
```   

Lists all available Fablo versions.

### use <version-number>

```bash
fablo use <version-number>
```   

Switches current script to selected version.

## Fablo config

Fablo config is a single JSON or YAML file that describes desired Hyperledger Fabric network topology (network settings, CA, orderer, organizations, peers, channels, chaincodes).
It has to be compatible with the [schema].
You may generate a basic config with `./fablo init` command.
See the [samples](https://github.com/hyperledger-labs/fablo/blob/main/samples/) directory for more complex examples.

The basic structure of Fablo config file is as follows:

```json
{
  "$schema": "https://github.com/hyperledger-labs/fablo/releases/download/1.0.0/schema.json",
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
    "fabricVersion": "2.3.0",
    "tls": false,
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

The other available parameters for entries in `orgs` array are:

 * `organization.mspName` (default: `organization.name + 'MSP'`)
 * `ca.prefix` (default: `ca`)
 * `ca.db` (default: `sqlite`, other: `postgres`)
 * `peer.prefix` (default: `peer`)
 * `peer.anchorPeerInstances` (default: `1`)
 * `orderers` (defaults to empty: `[]`)
 * `tools.explorer` - whether run Blockchain Explorer for the organization (default: `false`)
 * `tools.fabloRest` - whether run Fablo REST for the organization (default: `false`)
 
### property `peer.db`:  
- may be `LevelDb` (default) or `CouchDb`.  

###property `orderers`:  
- is optional as some organizations may have orderer defined, but some don't.
- At least one orderer group is required to run Fabric network (requirement is validated before run).   
- If you want to spread orderers in group between many organizations use same `groupName` in every group definition.  
- The property `orderers.type` may be `solo` or `raft`. We do not support the Kafka orderer.

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

- Property `groupName` is optional (defaults to first orderer group found). If you want to handle channel with different orderer group define it in `orgs` and pass it's name here. 

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
    },
    {
      "name": "chaincode2",
      "version": "0.0.1",
      "lang": "java",
      "channel": "my-channel2"
    }
  ]
```

The other available parameters for entries in `chaincodes` array are:

* `init` - initialization arguments (for Hyperledger Fabric below 2.0; default: `{"Args":[]}`)
* `initRequired` - whether the chaincode requires initialization transaction (for Hyperledger Fabric 2.0 and greater; default: `false`)
* `endorsement` - the endorsement policy for the chaincode (in case of missing value for Hyperledger Fabric 2.0 and greater there is no default value - Hyperledger by default will take the majority of organizations; for Hyperledger Fabric below 2.0 Fablo generates an endorsement policy where all organizations need to endorse)

The property `lang` may be `golang`, `java` or `node`.

The `privateData` parameter is optional. You don't need to define the private data collection for the chaincode. By default there is none (just the implicit private data collection in Fabric 2.x).

### hooks

Hooks in Fablo are Bash commands to be executed after a specific event.
Right now Fablo supports only one kind of hook: `postGenerate`.
It will be executed each time after the network config is generated -- after `./fablo generate` command (executed separately or automatically by `./fablo up`).

The following hook example will change `MaxMessageCount` to 1 in generated Hyperledger Fabric config:

```json
  "hooks": {
    "postGenerate": "perl -i -pe 's/MaxMessageCount: 10/MaxMessageCount: 1/g' \"./fablo-target/fabric-config/configtx.yaml\""
  }
```

Genrated Hooks are saved in `fablo-target/hooks`.


### Sample YAML config file

```yaml
---
"$schema": https://github.com/hyperledger-labs/fablo/releases/download/1.0.0/schema.json
global:
  fabricVersion: 2.3.0
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

## Other features

### Connection profiles

Fablo will generate the connection profiles for each organization defined in the configuration.
You can find them in `fablo-target/fablo-config/connection-profiles` directory in `json` and `yaml` format.

### REST API

Fablo is integrated with simple REST API for CA and chaincodes, supported by [Fablo REST](https://github.com/softwaremill/fablo-rest).
If you want to use it, provide for your organization `"tools": { "fabloRest": true }`.
Visit the [Fablo REST](https://github.com/softwaremill/fablo-rest) project for more documentation.

### Blockchain Explorer

Fablo can run [Blockchain Explorer](https://github.com/hyperledger/blockchain-explorer) for you.
Provide for your organization `"tools": { "explorer": true }`, if you want to use it per organization, or provide the same value in `global` section of the config, if you want to use one global Explorer for all organizations.

## Testimonials

Fablo was originally created at [SoftwareMill](https://softwaremill.com).
