![Github Actions](https://github.com/softwaremill/fabrica/actions/workflows/test.yml/badge.svg?branch=main)

<h1><img src="./logo.svg" alt="Fabrica"/></h1>

Fabrica supports:

* Environment: Docker
* RAFT and solo consensus protocols
* Multiple organizations and channels
* Chaincode installation and upgrade

## See it in action

[![How to use](https://img.youtube.com/vi/JqPNozCtHkQ/0.jpg)](https://www.youtube.com/watch?v=JqPNozCtHkQ)

## Installation

Fabrica is distributed as a single shell script which uses Docker image to generate the network config.
You may keep the script in the root directory of your project or install it globally in your file system.

To install it globally:

```bash
sudo curl -Lf https://github.com/softwaremill/fabrica/releases/download/0.1.0/fabrica.sh -o /usr/local/bin/fabrica && sudo chmod +x /usr/local/bin/fabrica
```

To get a copy of Fabrica for a single project, execute in the project root:

```bash
curl -Lf https://github.com/softwaremill/fabrica/releases/download/0.1.0/fabrica.sh -o ./fabrica && chmod +x ./fabrica
```

## Basic usage

```bash
fabrica up /path/to/fabrica-config.json
```

The `up` command creates initial configuration and starts Hyperledger Fabric network on Docker.
In this case network configuration is saved in `$(pwd)/fabrica-target`.
Then you can manage the network with other commands, for example `stop`, `start`, `down`, `prune`.

Provided Fabrica configuration file describes network topology: root organization, other organizations, channels and chaincodes.
See the [samples](https://github.com/softwaremill/fabrica/blob/main/samples/) or [Fabrica config](https://github.com/softwaremill/fabrica#fabrica-config) section.

There are two basic use cases.
You may use Fabrica to start and manage the network for development purposes, test different network topologies, run it in CI environment etc.
In this case you should keep `fabrika-target` directory intact and out of the version control.
Fabrica will manage it locally.

On the other hand you can use Fabrica to generate initial network configuration, keep it in version control and tweak for specific requirements.
In this case, however, you should use generated `fabrica-docker.sh` instead of `fabrica` script.

## Managing the network

### init

```bash
fabrica init [node]
```

Creates simple network config file in current dir.
Good step to start your adventure with Fabrica or set up a fast prototype. 

Option `node` makes Fabrica to generate a sample Node.js chaincode as well.

Generated `fabrica-config.json` file uses single node Solo consensus and no TLS support.
This is the simplest way to start with Hyperledger Fabric, since Raft consensus requires TLS and TLS itself adds a lot of complexity to the blockchain network and integration with it.

### generate

```bash
fabrica generate [/path/to/fabrica-config.json|yaml [/path/to/fabrica/target]]
```

Generates network configuration files in the given directory.
Default config file path is `$(pwd)/fabrica-config.json` or `\$(pwd)/fabrica-config.yaml`, default directory is `$(pwd)/fabrica-target`.
If you specify a different directory, you loose Fabrica support for other commands.

If you want to use Fabrica only to kick off the Hyperledger Fabric network, you may provide target directory parameter or just copy generated Fabrica target directory content to desired directory and add it to version control.
Note that generated files may contain variables with paths on your disk and generated crypto material for Hyperledger Fabric.
Review the files before submitting to version control system.

### up

```bash
fabrica up [/path/to/fabrica-config.json|yaml]
```

Starts the Hyperledger Fabric network for given Fabrica configuration file, creates channels, installs and instantiates chaincodes.
If there is no configuration, it will call `generate` command for given config file.

### down, start, stop

```bash
fabrica [down | start | stop]
```

Downs, starts or stops the Hyperledger Fabric network for configuration in the current directory.
This is similar to down, start and stop commands for Docker Compose.

### prune

```bash
fabrica prune
```

Downs the network and removes `fabrica-target` directory.

### reboot and recreate

```bash
fabrica reboot
fabrica recreate [/path/to/fabrica-config.json|yaml]
```

* `reboot` -- down and up steps combined. Network state is lost, but the configuration is kept intact. Useful in cases when you want a fresh instance of network without any state.
* `recreate` -- prunes the network, generates new config files and ups the network. Useful when you edited `fabrica-config` file and want to start newer network version in one command.    

### validate

```bash
fabrica validate [/path/to/fabrica-config.json|yaml]
```

Validates network config. This command will validate your network config try to suggest necessary changes or additional tweaks.
Please note that this step is also executed automatically before each `generate` to ensure that at least critical errors where fixed. 

### fabric-docker.sh

The script `fabric-docker.sh` is generated among docker network configuration.
It does not support `generate` command, however other commands work in same way as in `fabrica`.
Basically `fabrica` forwards some commands to this script.

## Managing chaincodes

### chaincode upgrade

```bash
fabrica chaincode upgrade chaincode-name version
```

Upgrades and instantiates chaincode with given name on all relevant peers.
Chaincode directory is specified in Fabrica config file.

## Managing channels

### chaincode channel

```bash
fabrica channel --help
```
Use it to list all available channel commands.  
Commands are generated using fabrica-config.json to cover all cases (queries for each channel. organization and peer)
 
```bash
fabrica channel list org1 peer0
```
lists all channels for given peer

```bash
fabrica channel getinfo channel_name org1 peer0
```
Prints channel info ei. current block height for given peer

```bash
fabrica channel fetch config channel_name org1 peer0 file_name.json
```
Fetches latest config block, decodes it and write to a json file.

```bash
fabrica channel fetch lastBlock channel_name org1 peer0 file_name.json
```
Fetches latest block, decodes it and write to a json file. It might be transaction block or config block.

```bash
fabrica channel fetch firstBlock channel_name org1 peer0 file_name.json
```
Fetches first block for given channel. Usually it will be initial channel configuration. 

## Utility commands

### version

```bash
fabrica version [--verbose | -v]
```
Prints current Fabrica version.
With optional `-v` or `--verbose` flag it prints supported Fabrica and Hyperledger Fabric versions as well.

### use

```bash
fabrica use
```   

Lists all available Fabrica versions.

### use <version-number>

```bash
fabrica use <version-number>
```   

Switches current script to selected version.

## Fabrica config

Fabrica config is a single JSON or YAML file that describes desired Hyperledger Fabric network topology (network settings, CA, orderer, organizations, peers, channels, chaincodes).
It has to be compatible with the [schema].
You may generate a basic config with `./fabrica init` command.
See the [samples](https://github.com/softwaremill/fabrica/blob/main/samples/) directory for more complex examples.

The basic structure of Fabrica config file is as follows:

```json
{
  "$schema": "https://github.com/softwaremill/fabrica/releases/download/0.1.0/schema.json",
  "networkSettings": { ... },
  "rootOrg": { ... },
  "orgs": [ ... ],
  "channels": [ ... ],
  "chaincodes": [ ... ]
}
```

### networkSettings

Example:

```json
  "networkSettings": {
    "fabricVersion": "2.3.0",
    "tls": false,
    "monitoring": {
      "loglevel": "debug"
    }
  },
```

### rootOrg

Example:

```json
  "rootOrg": {
    "organization": {
      "name": "Orderer",
      "domain": "root.com"
    },
    "orderer": {
      "type": "solo",
      "instances": 1
    }
  },
```

The other available parameters for `rootOrg` are:
 * `organization.mspName` (default: `organization.name + 'MSP'`)
 * `orderer.prefix` (default: `orderer`)
 * `ca.prefix` (default: `ca`)

The property `orderer.consensus` may be `solo` or `raft`. We do not support the Kafka orderer.

### orgs

Example:

```json
  "orgs": [
    {
      "organization": {
        "name": "Org1",
        "domain": "org1.com"
      },
      "peer": {
        "instances": 2,
        "db": "LevelDb"
      }
    },
    ...
  ],
```

The other available parameters for entries in `orgs` array are:

 * `organization.mspName` (default: `organization.name + 'MSP'`)
 * `ca.prefix` (default: `ca`)
 * `peer.prefix` (default: `peer`)
 * `peer.anchorPeerInstances` (default: `1`)

The property `peer.db` may be `LevelDb` (default) or `CouchDb`.

### channels

Example:

```json
  "channels": [
    {
      "name": "my-channel1",
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
      "channel": "my-channel2",
      "directory": "./chaincodes/chaincode-java-simple"
    }
  ]
```

The other available parameters for entries in `orgs` array are:

 * `init` - initialization arguments (for Hyperledger Fabric below 2.0; default: `{"Args":[]}`)
 * `initRequired` - whether the chaincode requires initialization transaction (for Hyperledger Fabric 2.0 and greater; default: `false`)
 * `endorsement` - the endorsement policy for the chaincode (in case of missing value for Hyperledger Fabric 2.0 and greater there is no default value - Hyperledger by default will take the majority of organizations; for Hyperledger Fabric below 2.0 Fabrica generates an endorsement policy where all organizations need to endorse)

The property `lang` may be `golang`, `java` or `node`.

The `privateData` parameter is optional. You don't need to define the private data collection for the chaincode. By default there is none.

### Sample YAML config file

```yaml
---
"$schema": https://github.com/softwaremill/fabrica/releases/download/0.1.0/schema.json
networkSettings:
  fabricVersion: 1.4.11
  tls: false
rootOrg:
  organization:
    name: Orderer
    domain: root.com
  orderer:
    prefix: orderer
    type: solo
    instances: 1
orgs:
  - organization:
      name: Org1
      domain: org1.com
    peer:
      instances: 2
  - organization:
      name: Org2
      domain: org2.com
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
    endorsement: AND('Org1MSP.member', 'Org2MSP.member')
    directory: "./chaincodes/chaincode-kv-node-1.4"
    privateData:
      - name: org1-collection
        orgNames:
          - Org1
```
