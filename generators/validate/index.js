/* eslint no-underscore-dangle: 0 */

/*
* License-Identifier: Apache-2.0
*/
const Generator = require('yeoman-generator');
const SchemaValidator = require('jsonschema').Validator;
const chalk = require('chalk');
const { supportedFabricaVersions, supportedFabricVersions, versionsSupportingRaft } = require('../config');
const Listener = require('../utils/listener');
const utils = require('../utils/utils');

const schema = require('../../docs/schema.json');
const config = require('../config');

const validationErrorType = {
  CRITICAL: 'validation-critical',
  ERROR: 'validation-error',
  WARN: 'validation-warning',
};

const validationCategories = {
  CRITICAL: 'Critical',
  GENERAL: 'General',
  ORDERER: 'Orderer',
  PEER: 'Peer',
  VALIDATION: 'Schema validation',
};

module.exports = class extends Generator {
  constructor(args, opts) {
    super(args, opts);

    this.argument('fabricaConfig', {
      type: String,
      required: true,
      description: 'fabrica config file path',
    });

    this.addListener(validationErrorType.CRITICAL, (event) => {
      this.log(chalk.bold.bgRed('Critical error occured:'));
      this.log(chalk.bold(`- ${event.message}`));
      this._printIfNotEmpty(this.listeners.error.getAllMessages(), chalk.red.bold('Errors found:'));
      process.exit();
    });

    this.listeners = { error: new Listener(), warn: new Listener() };

    this.addListener(validationErrorType.ERROR, (e) => this.listeners.error.onEvent(e));
    this.addListener(validationErrorType.WARN, (e) => this.listeners.warn.onEvent(e));
  }

  initializing() {
    this.log(config.splashScreen());
  }

  async validate() {
    this._validateIfConfigFileExists(this.options.fabricaConfig);

    const networkConfig = this.fs.readJSON(this.options.fabricaConfigPath);
    this._validateJsonSchema(networkConfig);
    this._validateSupportedFabricaVersion(networkConfig.fabricaVersion);
    this._validateFabricVersion(networkConfig.networkSettings.fabricVersion);

    this._validateOrdererCountForSoloType(networkConfig.rootOrg.orderer);
    this._validateOrdererForRaftType(networkConfig.rootOrg.orderer, networkConfig.networkSettings);

    this._validateOrgsAnchorPeerInstancesCount(networkConfig.orgs);
  }

  async summary() {
    this.log(`Errors count: ${this.listeners.error.count()}`);
    this.log(`Warnings count: ${this.listeners.warn.count()}`);
    this.log(chalk.bold('=================== Validation summary ==================='));

    this._printIfNotEmpty(this.listeners.error.getAllMessages(), chalk.red.bold('Errors found:'));
    this._printIfNotEmpty(this.listeners.warn.getAllMessages(), chalk.yellow('Warnings found:'));

    this.log(chalk.bold('==========================================================='));

    if (this.listeners.error.count() > 0) {
      process.exit();
    }
  }

  _validateIfConfigFileExists(configFilePath) {
    const configFilePathAbsolute = utils.getFullPathOf(configFilePath, this.env.cwd);
    const fileExists = this.fs.exists(configFilePathAbsolute);
    if (!fileExists) {
      const objectToEmit = {
        category: validationCategories.CRITICAL,
        message: `No file under path: ${configFilePathAbsolute}`,
      };
      this.emit(validationErrorType.CRITICAL, objectToEmit);
    } else {
      this.options.fabricaConfigPath = configFilePathAbsolute;
    }
  }

  _validateJsonSchema(configToValidate) {
    const validator = new SchemaValidator();
    const results = validator.validate(configToValidate, schema);
    results.errors.forEach((result) => {
      const msg = `${result.property} : ${result.message}`;
      const objectToEmit = {
        category: validationCategories.VALIDATION,
        message: msg,
      };
      this.emit(validationErrorType.ERROR, objectToEmit);
    });
    if (results.errors.length > 0) {
      const objectToEmit = {
        category: validationCategories.CRITICAL,
        message: 'Json schema validation failed!',
      };
      this.emit(validationErrorType.CRITICAL, objectToEmit);
    }
  }

  _printIfNotEmpty(messages, caption) {
    if (messages.length > 0) {
      this.log(caption);

      const grouped = utils.groupBy(messages, (msg) => msg.category);

      Array.from(grouped.keys()).forEach((key) => {
        this.log(chalk.bold(`  ${key}:`));
        grouped.get(key).forEach((msg) => this.log(`   - ${msg.message}`));
      });
    }
  }

  _validateSupportedFabricaVersion(fabricaVersion) {
    if (!supportedFabricaVersions.includes(fabricaVersion)) {
      const msg = `Config file points to '${fabricaVersion}' Fabrica version which is not supported. Supported versions are: ${supportedFabricaVersions}`
      const objectToEmit = {
        category: validationCategories.CRITICAL,
        message: msg,
      };
      this.emit(validationErrorType.CRITICAL, objectToEmit);
    }
  }

  _validateFabricVersion(fabricVersion) {
    if (!supportedFabricVersions.includes(fabricVersion)) {
      const objectToEmit = {
        category: validationCategories.GENERAL,
        message: `Hyperledger Fabric '${fabricVersion}' version is not supported. Supported versions are: ${supportedFabricVersions}`,
      };
      this.emit(validationErrorType.ERROR, objectToEmit);
    }
  }

  _validateOrdererCountForSoloType(orderer) {
    if (orderer.type === 'solo' && orderer.instances > 1) {
      const objectToEmit = {
        category: validationCategories.ORDERER,
        message: `Orderer consesus type is set to 'solo', but number of instances is ${orderer.instances}. Only 1 instance will be created.`,
      };
      this.emit(validationErrorType.WARN, objectToEmit);
    }
  }

  _validateOrdererForRaftType(orderer, networkSettings) {
    if (orderer.type === 'raft' || orderer.type === 'etcdraft') {
      if (orderer.instances === 1) {
        const objectToEmit = {
          category: validationCategories.ORDERER,
          message: `Orderer consesus type is set to '${orderer.type}', but number of instances is 1. Network won't be fault tolerant! Consider higher value.`,
        };
        this.emit(validationErrorType.WARN, objectToEmit);
      }

      if (!versionsSupportingRaft.includes(networkSettings.fabricVersion)) {
        const objectToEmit = {
          category: validationCategories.ORDERER,
          message: `Fabric's ${networkSettings.fabricVersion} does not support Raft consensus type. Supporting versions are: ${versionsSupportingRaft}`,
        };
        this.emit(validationErrorType.ERROR, objectToEmit);
      }

      if (!networkSettings.tls) {
        const objectToEmit = {
          category: validationCategories.ORDERER,
          message: "Raft consensus type must use network in TLS mode. Try setting 'networkSettings.tls' to true",
        };
        this.emit(validationErrorType.ERROR, objectToEmit);
      }
    }
  }

  _validateOrgsAnchorPeerInstancesCount(orgs) {
    orgs.forEach((org) => {
      const numberOfPeers = org.peer.instances;
      const numberOfAnchorPeers = org.peer.anchorPeerInstances;

      if (numberOfPeers < numberOfAnchorPeers) {
        const objectToEmit = {
          category: validationCategories.PEER,
          message: `Too many anchor peers for organization "${org.organization.name}". Peer count: ${numberOfPeers}, anchor peer count: ${numberOfAnchorPeers}`,
        };
        this.emit(validationErrorType.ERROR, objectToEmit);
      }
    });
  }
};
