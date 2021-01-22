## main (0.0.1)

### Features

* Generate simple Hyperledger Fabric network
* Support for multiple organizations
* Support for solo consensus protocol
* Support for RAFT consensus protocol ([#16](https://github.com/softwaremill/fabrica/issues/16), [#38](https://github.com/softwaremill/fabrica/issues/38))
* Validation of `fabrica-config.json` based on JSON schema and other rules
* Support Hyperledger Fabric 2.0 as well (without 2.0 capabilities, [#17](https://github.com/softwaremill/fabrica/issues/17))
* Allow to upgrade chaincode ([#45](https://github.com/softwaremill/fabrica/issues/36))
* Network recreation in one step ([#105](https://github.com/softwaremill/fabrica/issues/105))
* Init command to provide simple config ([#90](https://github.com/softwaremill/fabrica/issues/90))

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
