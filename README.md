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

The `up` command creates initial configuration and starts Hyperledger Fabric network on Docker. In this case network configuration is saved in `$(pwd)/fabrikka-target/network`. Then you can manage the network with other commands, for example `stop`, `start`, `down`.

Provided Fabrikka configuration file describes network topology: root organization, other organizations, channels and chaincodes. See the [samples](https://github.com/softwaremill/fabrikka/blob/main/samples/).

There are two basic use cases. You may use Fabrikka to start and manage the network for development purposes, test different network topologies, run it in CI environment etc. In this case you should keep `fabrika-target` directory intact and out of the version control. Fabrikka will manage it locally.

On the other hand you can use Fabrikka to generate initial network configuration, keep it in version control and tweak for specific requirements. In this case, however, you should use generated `fabrikka-docker.sh` instead of `fabrikka.sh`.

## Managing the network

### generate

```bash
fabrikka.sh generate [/path/to/fabrikka-config.json [/path/to/fabrikka/target]]
```

Generates network configuration files in the given directory. Default config file path is `$(pwd)/fabrikka-config.json`, default directory is `$(pwd)/fabrikka-target/network`. If you specify a different directory, you loose Fabrikka support for other commands.

If you want to use Fabrikka only to kick off the Hyperledger Fabric network, you may provide target directory parameter or just copy generated Fabrikka target directory content to desired directory and add it to version control. Note that generated files may contain variables with paths on your disk and generated crypto material for Hyperledger Fabric. Review the files before submitting to version control system.

### up

```bash
fabrikka.sh up [/path/to/fabrikka-config.json]
```

Starts the Hyperledger Fabric network for given Fabrikka configuration file, creates channels, installs and instantiates chaincodes. If there is no configuration, it will call `generate` command for given config file.

### down, start, stop

```bash
fabrikka.sh [down | start | stop]
```

Downs, starts or stops the Hyperledger Fabric network for configuration in the current directory. This is similar to down, start and stop commands for Docker Compose.

### fabric-docker.sh

This script `fabric-docker.sh` is generated among docker network configuration. It does not support `generate` command, however other commands work in same way as in `fabrikka.sh`. Basically `fabrikka.sh` forwards commands other than `generate` to this script. In most cases you can use `fabrikka.sh docker` and `fabric-docker.sh` interchangebly.

## Managing chaincodes
