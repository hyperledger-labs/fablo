## 2.5.0

### Features
* Add MySQL database support for CA [#618](https://github.com/hyperledger-labs/fablo/pull/618)
* Quick start [#645](https://github.com/hyperledger-labs/fablo/pull/645)

### Bug Fixes
* Get chaincode container name by peer address instead of index [#649](https://github.com/hyperledger-labs/fablo/pull/649)
* Empty chaincode directory mount [#651](https://github.com/hyperledger-labs/fablo/pull/651)
* Show duplicated chaincodes in mermaid [#639](https://github.com/hyperledger-labs/fablo/pull/639)
* Quick installation URL fix [#646](https://github.com/hyperledger-labs/fablo/pull/646)

### Testing
* Fix flaky snapshot ccaas test [#648](https://github.com/hyperledger-labs/fablo/pull/648)

### Chore & Maintenance
* Bump lodash from 4.17.21 to 4.17.23 [#650](https://github.com/hyperledger-labs/fablo/pull/650)

## 2.4.3

### Chore & Maintenance
* Update Node.js to 20 [#641](https://github.com/hyperledger-labs/fablo/pull/641)

### Documentation
* Update `README.md` to provide talk links [#637](https://github.com/hyperledger-labs/fablo/pull/637)


## 2.4.2

### Bug Fixes
* Update chaincode image for init CCaaS command [#634](https://github.com/hyperledger-labs/fablo/pull/634)
* Add missing orderers and improve style in Mermaid diagrams [#635](https://github.com/hyperledger-labs/fablo/pull/635)

## 2.4.1

### Features
* `fablo init ccaas` command [#630](https://github.com/hyperledger-labs/fablo/pull/630)

## Documentation
* Update supported features hooks documentation [#629](https://github.com/hyperledger-labs/fablo/pull/629)

### Chore & Maintenance
* Set Fabric 3.1.0 as the default one for tests [#626](https://github.com/hyperledger-labs/fablo/pull/626)
* Fix wrong script file name in release GH action [#631](https://github.com/hyperledger-labs/fablo/pull/631)


## 2.4.0

### Features
* CCaaS dev mode [#622](https://github.com/hyperledger-labs/fablo/pull/622)
* Support chaincodes with the same name but on different channels [#607](https://github.com/hyperledger-labs/fablo/pull/607)
* Add post-start hook executed after up/start [#616](https://github.com/hyperledger-labs/fablo/pull/616)
* Detect changes in `fablo-config.json` to prevent reusing old network by accident [#614](https://github.com/hyperledger-labs/fablo/pull/614)

### Bug Fixes
* Hardcoded CCaaS cert [#621](https://github.com/hyperledger-labs/fablo/pull/621)
* Use proper certificates in multiple orderer groups setup [be5e462](https://github.com/hyperledger-labs/fablo/commit/be5e4629550fc74b74a64d472956c9b4dd372363)
* Restart Explorer once channels are created [#615](https://github.com/hyperledger-labs/fablo/pull/615)

## Documentation
* Update supported features [#617](https://github.com/hyperledger-labs/fablo/pull/617)

## 2.3.0

### Features
* Support for running Java chaincode in development mode [#553](https://github.com/hyperledger-labs/fablo/pull/553)
* Support installing Chaincode from Docker image using CCaaS [#550](https://github.com/hyperledger-labs/fablo/pull/550) [#582](https://github.com/hyperledger-labs/fablo/pull/582) [#594](https://github.com/hyperledger-labs/fablo/pull/594)
* Export network topology with Mermaid [#565](https://github.com/hyperledger-labs/fablo/pull/565) [#579](https://github.com/hyperledger-labs/fablo/pull/579)
* Generate diagrams by default for each 'generate' command [#584](https://github.com/hyperledger-labs/fablo/pull/584)
* Added Fablo Sample Gateway Connection for Node.js [#541](https://github.com/hyperledger-labs/fablo/pull/541)
* Adds gateway option to init [#544](https://github.com/hyperledger-labs/fablo/pull/544)
* Support query command for docker setup [#597](https://github.com/hyperledger-labs/fablo/pull/597)
* Add orderers and channels in connection profile [#595](https://github.com/hyperledger-labs/fablo/pull/595)
* Add check for unique chaincode names [#596](https://github.com/hyperledger-labs/fablo/pull/596)
* Hardcode fablo config inside init generator [#554](https://github.com/hyperledger-labs/fablo/pull/554)
* Publish sample chaincode Docker image [#555](https://github.com/hyperledger-labs/fablo/pull/555)
* Include and test Sample Go chaincode in samples/chaincodes/chaincode-kv-go [#569](https://github.com/hyperledger-labs/fablo/pull/569)

### Bug Fixes
* Verify if post-generate.sh exists before executing [#521](https://github.com/hyperledger-labs/fablo/pull/521) [#526](https://github.com/hyperledger-labs/fablo/pull/526)
* Fix chaincode invoke CLI for endorsement policy involving multiple peers [#549](https://github.com/hyperledger-labs/fablo/pull/549)
* Fix tag format for release CI [#504](https://github.com/hyperledger-labs/fablo/pull/504)
* Fix missing FABLO_VERSION in publish docker workflow [#556](https://github.com/hyperledger-labs/fablo/pull/556)
* CI: Update release workflow to match proper version tagging [#516](https://github.com/hyperledger-labs/fablo/pull/516)
* Fix Gradle build for Java chaincode [#583](https://github.com/hyperledger-labs/fablo/pull/583)

### Documentation
* Docs: Clarify usage of global vs local fablo installation in README [#520](https://github.com/hyperledger-labs/fablo/pull/520)
* Fix: correct typo in CONTRIBUTING.md [#538](https://github.com/hyperledger-labs/fablo/pull/538)
* Docs: Coverage tracker / supported features [#557](https://github.com/hyperledger-labs/fablo/pull/557) [#564](https://github.com/hyperledger-labs/fablo/pull/564) [#562](https://github.com/hyperledger-labs/fablo/pull/562) [#566](https://github.com/hyperledger-labs/fablo/pull/566) [#563](https://github.com/hyperledger-labs/fablo/pull/563) [#570](https://github.com/hyperledger-labs/fablo/pull/570) [#586](https://github.com/hyperledger-labs/fablo/pull/586)

### Testing & CI
* Test cases for `repositoryUtils.ts` [#548](https://github.com/hyperledger-labs/fablo/pull/548)
* Unit tests for `parseFabloConfig` [#552](https://github.com/hyperledger-labs/fablo/pull/552)
* Test golang chaincode in Github Actions [#569](https://github.com/hyperledger-labs/fablo/pull/569)
* Test post-generate hook creation and execution in CI [#580](https://github.com/hyperledger-labs/fablo/pull/580)
* Test peer dev mode [#592](https://github.com/hyperledger-labs/fablo/pull/592)
* Test Gateway client [#587](https://github.com/hyperledger-labs/fablo/pull/587)
* Test: Test CCaaS for Fabric v3 [#603](https://github.com/hyperledger-labs/fablo/pull/603)

### Chore & Maintenance
* Bump all dependencies from Dependabot PRs [#600](https://github.com/hyperledger-labs/fablo/pull/600)
* Unify Fabric version in tests and samples [#581](https://github.com/hyperledger-labs/fablo/pull/581)
* Upgrade Blockchain Explorer [#590](https://github.com/hyperledger-labs/fablo/pull/590)

## 2.2.0

### Features
* Full support for Fabric 3.0.0 and drop solo consensus [#513](https://github.com/hyperledger-labs/fablo/pull/513)

### Bug Fixes
* Fix connection profile issues (CA URL, missing orderers and channels sections) [#340](https://github.com/hyperledger-labs/fablo/issues/340)

## 2.1.0

### Features
* Support Fabric 3.0.0-beta, along with BFT consensus [#501](https://github.com/hyperledger-labs/fablo/pull/501)

## 2.0.0

### Breaking changes
* Drop support for capabilities v1, and Fabric versions below 2.0.0 [#461](https://github.com/hyperledger-labs/fablo/pull/461) [#462](https://github.com/hyperledger-labs/fablo/pull/462) [#464](https://github.com/hyperledger-labs/fablo/pull/464) [#473](https://github.com/hyperledger-labs/fablo/pull/473) [#486](https://github.com/hyperledger-labs/fablo/pull/486) [#488](https://github.com/hyperledger-labs/fablo/pull/488)
* Drop yarn and nvm installation support [#455](https://github.com/hyperledger-labs/fablo/pull/455)

### Features
* Add application capability V_2_5 [#463] [#463](https://github.com/hyperledger-labs/fablo/pull/463)
* Support for `chaincode invoke` command (tls and non-tls) [#403](https://github.com/hyperledger-labs/fablo/pull/403)
* [#413](https://github.com/hyperledger-labs/fablo/pull/413)
* Support for `chaincodes list` command (tls and non-tls) [#409](https://github.com/hyperledger-labs/fablo/pull/409) [#411](https://github.com/hyperledger-labs/fablo/pull/411)
* Christmas easter egg [#427](https://github.com/hyperledger-labs/fablo/pull/427)
* Remove dev dependencies on chaincode installation for Node.js [#450](https://github.com/hyperledger-labs/fablo/pull/450)
* Update Fabric version in the initial configuration [#470]( https://github.com/hyperledger-labs/fablo/pull/470)
* Publish Fablo Docker image for ARM architecture [#478](https://github.com/hyperledger-labs/fablo/pull/478) [#487](https://github.com/hyperledger-labs/fablo/pull/487)

### Fixes
* Fixed https request when tls is enabled [#438](https://github.com/hyperledger-labs/fablo/pull/438)
* Fixed issue with `fablo up` command when using CouchDB [#443](https://github.com/hyperledger-labs/fablo/pull/443)
* Update Docker Compose command [#465](https://github.com/hyperledger-labs/fablo/pull/465)
* Fixed issue with private data collection [#460]( https://github.com/hyperledger-labs/fablo/pull/467)
* Updated Node.js version from 12 to 16 in chaincode
* Remove unsupported test library and dependencies

### Chore & Maintenance
* Add contributing guidelines [#439](https://github.com/hyperledger-labs/fablo/pull/439)
* Documented the Fablo architecture in `ARCHITECTURE.md` file [#456](https://github.com/hyperledger-labs/fablo/pull/456)
* Changed recommended Node.js version check [#442](https://github.com/hyperledger-labs/fablo/pull/442)
* Library updates (mostly by Dependabot)
* Various CI improvements and fixes [#467](https://github.com/hyperledger-labs/fablo/pull/467) [#458](https://github.com/hyperledger-labs/fablo/pull/458) [#489](https://github.com/hyperledger-labs/fablo/pull/489)
* Improve .gitignore file [#476]( https://github.com/hyperledger-labs/fablo/pull/476)
* Update Fablo docker image registry to GHCR [#491](https://github.com/hyperledger-labs/fablo/pull/491)

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
* Added channel query scripts ([#169](https://github.com/hyperledger-labs/fablo/issues/169))
* Support for Hyperledger Fabric 2.x ([#132](https://github.com/hyperledger-labs/fablo/issues/132) [#178](https://github.com/hyperledger-labs/fablo/issues/178) [#190](https://github.com/hyperledger-labs/fablo/issues/178))
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

