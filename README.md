<h1><img src="./logo.svg" alt="Fabrica"/></h1>

Supports:

* Environment: Docker
* RAFT and solo consensus protocol
* Multiple orgs and channels
* Chaincode installation

## Basic usage

```bash
fabrica.sh up /path/to/fabrica-config.json
```

The `up` command creates initial configuration and starts Hyperledger Fabric network on Docker. In this case network configuration is saved in `$(pwd)/fabrica-target/network`. Then you can manage the network with other commands, for example `stop`, `start`, `down`.

Provided Fabrica configuration file describes network topology: root organization, other organizations, channels and chaincodes. See the [samples](https://github.com/softwaremill/fabrica/blob/main/samples/).

There are two basic use cases. You may use Fabrica to start and manage the network for development purposes, test different network topologies, run it in CI environment etc. In this case you should keep `fabrika-target` directory intact and out of the version control. Fabrica will manage it locally.

On the other hand you can use Fabrica to generate initial network configuration, keep it in version control and tweak for specific requirements. In this case, however, you should use generated `fabrica-docker.sh` instead of `fabrica.sh`.

## Utility commands

### version
```bash
fabrica.sh version [--verbose | -v]
```
Prints current Fabrica version. With optional flag `-v` added it will also print supported Fabrica and Hyperledger Fabric versions.

### use
```bash
fabrica.sh use
```   

Lists all available Fabrica versions.

### use <version-number>
```bash
fabrica.sh use <version-number>
```   

Switches current script to selected version


## Managing the network

### init
```bash
fabrica.sh init
```

Creates simple network config file in current dir.  
Good step to start your adventure with Fabrica or set fas prototype. 

### generate

```bash
fabrica.sh generate [/path/to/fabrica-config.json [/path/to/fabrica/target]]
```

Generates network configuration files in the given directory. Default config file path is `$(pwd)/fabrica-config.json`, default directory is `$(pwd)/fabrica-target`. If you specify a different directory, you loose Fabrica support for other commands.

If you want to use Fabrica only to kick off the Hyperledger Fabric network, you may provide target directory parameter or just copy generated Fabrica target directory content to desired directory and add it to version control. Note that generated files may contain variables with paths on your disk and generated crypto material for Hyperledger Fabric. Review the files before submitting to version control system.

### up

```bash
fabrica.sh up [/path/to/fabrica-config.json]
```

Starts the Hyperledger Fabric network for given Fabrica configuration file, creates channels, installs and instantiates chaincodes. If there is no configuration, it will call `generate` command for given config file.

### down, start, stop

```bash
fabrica.sh [down | start | stop]
```

Downs, starts or stops the Hyperledger Fabric network for configuration in the current directory. This is similar to down, start and stop commands for Docker Compose.

### prune

```bash
fabrica.sh prune
```

Downs the network and removes `fabrica-target` directory.

### validate
```bash
fabrica.sh validate [/path/to/fabrica-config.json]
```

Validates network config. This command will validate your network config try to suggest necessary changes or additional tweaks. Please note that this step is also executed automatically before each `generate` to ensure that at least critical errors where fixed. 

### fabric-docker.sh

The script `fabric-docker.sh` is generated among docker network configuration. It does not support `generate` command, however other commands work in same way as in `fabrica.sh`. Basically `fabrica.sh` forwards commands other than `generate` to this script. In most cases you can use `fabrica.sh docker` and `fabric-docker.sh` interchangebly.

## Managing chaincodes

### chaincode upgrade

```bash
fabrica.sh chaincode upgrade chaincode-name version
```

Upgrades and instantiates chaincode with given name on all relevant peers. Chaincode directory is specified in Fabrica config file.
