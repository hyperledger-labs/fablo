## 2.3.0

### Features
* Hardcode fablo config inside init generator
  [#554](https://github.com/hyperledger-labs/fablo/pull/554)
* Publish sample chaincode Docker image
  [#555](https://github.com/hyperledger-labs/fablo/pull/555)


## 2.2.0

### Features
* Full support for Fabric 3.0.0 and drop solo consensus
  [#513](https://github.com/hyperledger-labs/fablo/pull/513)

## 2.1.0

### Features
* Support Fabric 3.0.0-beta, along with BFT consensus
  [#501](https://github.com/hyperledger-labs/fablo/pull/501)

## 2.0.0

### Breaking changes
* Drop support for capabilities v1, and Fabric versions below 2.0.0
  [#461](https://github.com/hyperledger-labs/fablo/pull/461)
  [#462](https://github.com/hyperledger-labs/fablo/pull/462)
  [#464](https://github.com/hyperledger-labs/fablo/pull/464)
  [#473](https://github.com/hyperledger-labs/fablo/pull/473)
  [#486](https://github.com/hyperledger-labs/fablo/pull/486)
  [#488](https://github.com/hyperledger-labs/fablo/pull/488)
* Drop yarn and nvm installation support
  [#455](https://github.com/hyperledger-labs/fablo/pull/455)

### Features
* Add application capability V_2_5 [#463]
  [#463](https://github.com/hyperledger-labs/fablo/pull/463)
* Support for `chaincode invoke` command (tls and non-tls)
  [#403](https://github.com/hyperledger-labs/fablo/pull/403)
* [#413](https://github.com/hyperledger-labs/fablo/pull/413)
* Support for `chaincodes list` command (tls and non-tls)
  [#409](https://github.com/hyperledger-labs/fablo/pull/409)
  [#411](https://github.com/hyperledger-labs/fablo/pull/411)
* Christmas easter egg
  [#427](https://github.com/hyperledger-labs/fablo/pull/427)
* Remove dev dependencies on chaincode installation for Node.js
  [#450](https://github.com/hyperledger-labs/fablo/pull/450)
* Update Fabric version in the initial configuration
  [#470]( https://github.com/hyperledger-labs/fablo/pull/470)
* Publish Fablo Docker image for ARM architecture
  [#478](https://github.com/hyperledger-labs/fablo/pull/478)
  [#487](https://github.com/hyperledger-labs/fablo/pull/487)

### Fixes
* Fixed https request when tls is enabled
  [#438](https://github.com/hyperledger-labs/fablo/pull/438)
* Fixed issue with `fablo up` command when using CouchDB
  [#443](https://github.com/hyperledger-labs/fablo/pull/443)
* Update Docker Compose command
  [#465](https://github.com/hyperledger-labs/fablo/pull/465)
* Fixed issue with private data collection
  [#460]( https://github.com/hyperledger-labs/fablo/pull/467)
* Updated Node.js version from 12 to 16 in chaincode
* Remove unsupported test library and dependencies

### Chore & Maintenance
* Add contributing guidelines
  [#439](https://github.com/hyperledger-labs/fablo/pull/439)
* Documented the Fablo architecture in `ARCHITECTURE.md` file
  [#456](https://github.com/hyperledger-labs/fablo/pull/456)
* Changed recommended Node.js version check
  [#442](https://github.com/hyperledger-labs/fablo/pull/442)
* Library updates (mostly by Dependabot)
* Various CI improvements and fixes
  [#467](https://github.com/hyperledger-labs/fablo/pull/467)
  [#458](https://github.com/hyperledger-labs/fablo/pull/458)
  [#489](https://github.com/hyperledger-labs/fablo/pull/489)
* Improve .gitignore file
  [#476]( https://github.com/hyperledger-labs/fablo/pull/476)
* Update Fablo docker image registry to GHCR
  [#491](https://github.com/hyperledger-labs/fablo/pull/491)

## 1.2.0

### Features
* Initial Kubernetes support [#351](https://github.com/hyperledger-labs/fablo/issues/351)
(not yet so elastic like Fablo in terms of network topology, but ready for first views and comments)

### Chore & Maintenance
* Library updates


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
* Add [Fablo REST](https://github.com/fablo-io/fablo-rest/) support 
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

