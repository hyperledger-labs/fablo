## 1.1.0

### Features
* Support Fabric Gateway since Fabric 2.4 [#305](https://github.com/hyperledger-labs/fablo/issues/305)
* Introduce pre-restore hook
* Attach `fabric-ca-server-config.yaml` as a volume [#168](https://github.com/hyperledger-labs/fablo/issues/168)
* Support tls for CA [#229](https://github.com/hyperledger-labs/fablo/issues/229)
* Use nvm to switch node version for chaincode build
* Allow to run peers in dev mode [#126](https://github.com/hyperledger-labs/fablo/issues/126)
* Allow to install each chaincode manually

### Fixes
* Support Apple M1 / arm64 architecture
* Various fixes in channel scripts
* Remove remaining docker containers and images after prune

### Chore & Maintenance
* Add `fabricNodeenvVersion` global configuration
* Update Node.js runtime compatibility ([details](https://github.com/hyperledger-labs/fablo/issues/274))
* Update legacy URLs

## 1.0.2

### Features

### Fixes

### Chore & Maintenance
* Expose peer and orderer Prometheus metrics

## 1.0.0

### Features
* Generate connection profiles for organizations
* Create a full network state snapshot in tar.gz file and restore it
* Add [Hyperledger Explorer](https://github.com/hyperledger/blockchain-explorer) support
* Support postgres database for CA

### Fixes

### Chore & Maintenance
* Command 'reboot' renamed to 'reset'
* Keyword `function` removed from scripts for better portability
* Use the official CouchDB image for peer database

## 0.3.0

### Features
* Add [Fablo REST](https://github.com/softwaremill/fablo-rest/) support 
* By default all peers are anchor peers
* Support `postGenerate` hook
* Added support for [Orderer sharding](https://github.com/hyperledger-labs/fablo/issues/220) (multiple orderer groups).
* Support for [Orderer groups](https://github.com/hyperledger-labs/fablo/issues/238) (orderer group can be spread between many orgs).

### Fixes
* Fixed issue with bad `requiredPeerCount` in private data collection
* Fixed issues with `fablo up` on older bash versions ([details](https://github.com/hyperledger-labs/fablo/issues/210))

### Chore & Maintenance

## 0.2.0
* Rename Fabrica to Fablo

## 0.1.1
* Broken Node.js chaincode build ([#211](https://github.com/hyperledger-labs/fablo/pull/211))

## 0.1.0

### Features
* Support for private data ([#104](https://github.com/hyperledger-labs/fablo/issues/104))
* Added channel query scripts  ([#169](https://github.com/hyperledger-labs/fablo/issues/169))
* Support for Hyperledger Fabric 2.x ([#132](https://github.com/hyperledger-labs/fablo/issues/132)
  , [#178](https://github.com/hyperledger-labs/fablo/issues/178), [#190](https://github.com/hyperledger-labs/fablo/issues/178))
* Support default endorsement policy ([#189](https://github.com/hyperledger-labs/fablo/issues/189))
* Support for fablo config in YAML format

### Chore & Maintenance
* Use different config format and provide defaults
* Rewrite Yeoman generators to use TypeScript

## 0.0.1

### Features
* Generate simple Hyperledger Fabric network
* Support for multiple organizations
* Support for solo consensus protocol
* Support for RAFT consensus protocol ([#16](https://github.com/hyperledger-labs/fablo/issues/16)
  , [#38](https://github.com/hyperledger-labs/fablo/issues/38))
* Validation of `fablo-config.json` based on JSON schema and other rules
* Allow to upgrade chaincode ([#45](https://github.com/hyperledger-labs/fablo/issues/36))
* Network recreation in one step ([#105](https://github.com/hyperledger-labs/fablo/issues/105))
* Init command to provide simple config ([#90](https://github.com/hyperledger-labs/fablo/issues/90)) with
  chaincode ([#100](https://github.com/hyperledger-labs/fablo/issues/100))
* Proper exposing Orderer and Peers ports for service
  discovery ([#116](https://github.com/hyperledger-labs/fablo/issues/116))

### Fixes
* Missing notify anchor peers step ([#26](https://github.com/hyperledger-labs/fablo/issues/26))

### Chore & Maintenance
* Lint bash and YAML files ([#48](https://github.com/hyperledger-labs/fablo/issues/48))
* Format generated scripts and YAML files ([#75](https://github.com/hyperledger-labs/fablo/issues/75))
* Test Java chaincode on generated network ([#25](https://github.com/hyperledger-labs/fablo/issues/25))
* Test JS chaincode on generated network ([#46](https://github.com/hyperledger-labs/fablo/issues/46))
* Test generated Hyperledger Fabric networks ([#36](https://github.com/hyperledger-labs/fablo/issues/36))
* Test generators with simple snapshot tests ([#5](https://github.com/hyperledger-labs/fablo/issues/5))
* Lint JS files ([#1](https://github.com/hyperledger-labs/fablo/issues/1))
* Run Yeoman generators inside Docker container

