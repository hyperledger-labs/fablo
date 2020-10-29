# Fabrikka

Simple tool to kick-off your Hyperledger Fabric network.

Supports:

* Environment: Docker
* RAFT and solo consensus protocol
* Multiple orgs and channels
* Chaincode installation

## Basic usage

```bash
fabrikka.sh up /path/to/fabrikka-config.json
```

This command will create initial configuration and start Hyperledger Fabric network on Docker. All network configuration is saved in current directory (`pwd`), as well as `fabrikka-docker.sh` script to manage the network.

Provided Fabrikka configuration file describes network topology: root organization, other organizations, channels and chaincodes. See the [samples](https://github.com/softwaremill/fabrikka/blob/main/samples/).

There are two basic use cases. You may use Fabrikka to start and manage the network for development purposes, test different network topologies, run it in CI environment etc. On the other hand you can use Fabrikka to generate initial network configuration, keep it in version control and tweak for specific requirements.

## Managing the network

### generate

```bash
fabrikka.sh generate [/path/to/fabrikka-config.json [/path/to/fabrikka/target]]
```
Generates network configuration files in the given directory. Default config file path is `$(pwd)/fabrikka-config.json`, default (and recommended) directory `$(pwd)/.fabrikka`.

### up

```bash
fabrikka.sh up [/path/to/fabrikka-config.json]
```
Starts the Hyperledger Fabric network for configuration in the current directory. If there is no configuration, it will call `generate` command for given config file.

### down, start, stop

```bash
fabrikka.sh [down | start | stop]
```
Downs, starts or stops the Hyperledger Fabric network for configuration in the current directory. (Similar to down, start and stop commands for Docker Compose).

### fabrikka-docker.sh

This script `fabrikka-docker.sh` is generated among docker network configuration. It does not support `generate` command, however other commands work in same way as in `fabrikka.sh`. Basically `fabrikka.sh` forwards commands other than `generate` to this script. In most cases you can use `fabrikka.sh docker` and `fabrikka-docker.sh` interchangebly.

## Managing chaincodes

### Installing a chaincode

```bash
fabrikka.sh docker chaincodes install
```

Installs all chaincodes configured in Fabrikka config file.

## Getting pure network config

By default Fabrikka generates network configuration in `.fabrikka` directory. It should not be kept out of version control since it may contain absolute paths.

If you want to use Fabrikka only to kick off the Hyperledger Fabric network, you may provide target directory parameter to `fabrikka.sh generate` or just copy generated `.fabrikka` directory content to desired directory and add it to version control. Note that generated files may contain variables with paths on your disk and generated crypto material for Hyperledger Fabric.

