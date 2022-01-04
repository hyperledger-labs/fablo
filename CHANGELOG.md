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
* Added support for [Orderer sharding](https://github.com/softwaremill/fablo/issues/220) (multiple orderer groups).
* Support for [Orderer groups](https://github.com/softwaremill/fablo/issues/238) (orderer group can be spread between many orgs).

### Fixes
* Fixed issue with bad `requiredPeerCount` in private data collection
* Fixed issues with `fablo up` on older bash versions ([details](https://github.com/softwaremill/fablo/issues/210))

### Chore & Maintenance

## 0.2.0
* Rename Fabrica to Fablo

## 0.1.1
* Broken Node.js chaincode build ([#211](https://github.com/softwaremill/fablo/pull/211))

## 0.1.0

### Features
* Support for private data ([#104](https://github.com/softwaremill/fablo/issues/104))
* Added channel query scripts  ([#169](https://github.com/softwaremill/fablo/issues/169))
* Support for Hyperledger Fabric 2.x ([#132](https://github.com/softwaremill/fablo/issues/132)
  , [#178](https://github.com/softwaremill/fablo/issues/178), [#190](https://github.com/softwaremill/fablo/issues/178))
* Support default endorsement policy ([#189](https://github.com/softwaremill/fablo/issues/189))
* Support for fablo config in YAML format

### Chore & Maintenance
* Use different config format and provide defaults
* Rewrite Yeoman generators to use TypeScript

## 0.0.1

### Features
* Generate simple Hyperledger Fabric network
* Support for multiple organizations
* Support for solo consensus protocol
* Support for RAFT consensus protocol ([#16](https://github.com/softwaremill/fablo/issues/16)
  , [#38](https://github.com/softwaremill/fablo/issues/38))
* Validation of `fablo-config.json` based on JSON schema and other rules
* Allow to upgrade chaincode ([#45](https://github.com/softwaremill/fablo/issues/36))
* Network recreation in one step ([#105](https://github.com/softwaremill/fablo/issues/105))
* Init command to provide simple config ([#90](https://github.com/softwaremill/fablo/issues/90)) with
  chaincode ([#100](https://github.com/softwaremill/fablo/issues/100))
* Proper exposing Orderer and Peers ports for service
  discovery ([#116](https://github.com/softwaremill/fablo/issues/116))

### Fixes
* Missing notify anchor peers step ([#26](https://github.com/softwaremill/fablo/issues/26))

### Chore & Maintenance
* Lint bash and YAML files ([#48](https://github.com/softwaremill/fablo/issues/48))
* Format generated scripts and YAML files ([#75](https://github.com/softwaremill/fablo/issues/75))
* Test Java chaincode on generated network ([#25](https://github.com/softwaremill/fablo/issues/25))
* Test JS chaincode on generated network ([#46](https://github.com/softwaremill/fablo/issues/46))
* Test generated Hyperledger Fabric networks ([#36](https://github.com/softwaremill/fablo/issues/36))
* Test generators with simple snapshot tests ([#5](https://github.com/softwaremill/fablo/issues/5))
* Lint JS files ([#1](https://github.com/softwaremill/fablo/issues/1))
* Run Yeoman generators inside Docker container

