## main (0.2.0-unstable)

### Features

### Fixes
* Broken Node.js chaincode build ([#211](https://github.com/softwaremill/fabrica/pull/211))

### Chore & Maintenance

## 0.1.0

### Features
* Support for private data ([#104](https://github.com/softwaremill/fabrica/issues/104))
* Added channel query scripts  ([#169](https://github.com/softwaremill/fabrica/issues/169))
* Support for Hyperledger Fabric 2.x ([#132](https://github.com/softwaremill/fabrica/issues/132), [#178](https://github.com/softwaremill/fabrica/issues/178), [#190](https://github.com/softwaremill/fabrica/issues/178))
* Support default endorsement policy ([#189](https://github.com/softwaremill/fabrica/issues/189))
* Support for fabrica config in YAML format

### Chore & Maintenance
* Use different config format and provide defaults
* Rewrite Yeoman generators to use TypeScript

## 0.0.1

### Features
* Generate simple Hyperledger Fabric network
* Support for multiple organizations
* Support for solo consensus protocol
* Support for RAFT consensus protocol ([#16](https://github.com/softwaremill/fabrica/issues/16), [#38](https://github.com/softwaremill/fabrica/issues/38))
* Validation of `fabrica-config.json` based on JSON schema and other rules
* Allow to upgrade chaincode ([#45](https://github.com/softwaremill/fabrica/issues/36))
* Network recreation in one step ([#105](https://github.com/softwaremill/fabrica/issues/105))
* Init command to provide simple config ([#90](https://github.com/softwaremill/fabrica/issues/90)) with chaincode ([#100](https://github.com/softwaremill/fabrica/issues/100))
* Proper exposing Orderer and Peers ports for service discovery ([#116](https://github.com/softwaremill/fabrica/issues/116))

### Fixes
* Missing notify anchor peers step ([#26](https://github.com/softwaremill/fabrica/issues/26))

### Chore & Maintenance
* Lint bash and YAML files ([#48](https://github.com/softwaremill/fabrica/issues/48))
* Format generated scripts and YAML files ([#75](https://github.com/softwaremill/fabrica/issues/75))
* Test Java chaincode on generated network ([#25](https://github.com/softwaremill/fabrica/issues/25))
* Test JS chaincode on generated network ([#46](https://github.com/softwaremill/fabrica/issues/46))
* Test generated Hyperledger Fabric networks ([#36](https://github.com/softwaremill/fabrica/issues/36))
* Test generators with simple snapshot tests ([#5](https://github.com/softwaremill/fabrica/issues/5))
* Lint JS files ([#1](https://github.com/softwaremill/fabrica/issues/1))
* Run Yeoman generators inside Docker container

