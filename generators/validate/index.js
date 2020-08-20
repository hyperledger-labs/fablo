/* eslint no-underscore-dangle: 0 */

/*
* License-Identifier: Apache-2.0
*/
const Generator = require('yeoman-generator');
const chalk = require('chalk');
const { supportedFabrikkaVersions, supportedFabricVersions } = require('../config');

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
};

module.exports = class extends Generator {
  constructor(args, opts) {
    super(args, opts);

    this.argument('fabrikkaConfig', {
      type: String,
      required: true,
      description: 'fabrikka config file path',
    });

    this.addListener(validationErrorType.CRITICAL, (event) => {
      this.log('Critical error occured: ');
      this.log(`   ${event.message}`);
      process.exit();
    });

    this.listeners.error = {
      messages: [],
      onEvent: (event) => {
        this.listeners.error.messages.push(event);
      },
      count: () => this.listeners.error.messages.length,
    };

    this.listeners.warn = {
      messages: [],
      onEvent: (event) => {
        this.listeners.warn.messages.push(event);
      },
      count: () => this.listeners.warn.messages.length,
    };

    this.addListener(validationErrorType.ERROR, this.listeners.error.onEvent);
    this.addListener(validationErrorType.WARN, this.listeners.warn.onEvent);
  }

  _validateIfConfigFileExists(configFilePath) {
    const configFilePathAbsolute = this._getFullPathOf(configFilePath);
    const fileExists = this.fs.exists(configFilePathAbsolute);
    if (!fileExists) {
      const objectToEmit = {
        category: validationCategories.CRITICAL,
        message: `No file under path: ${configFilePathAbsolute}`,
      };
      this.emit(validationErrorType.CRITICAL, objectToEmit);
    } else {
      this.options.fabrikkaConfigPath = configFilePathAbsolute;
    }
  }

  async validate() {
    this._validateIfConfigFileExists(this.options.fabrikkaConfig);

    const networkConfig = this.fs.readJSON(this.options.fabrikkaConfigPath);
    this._validateSupportedFabrikkaVersion(networkConfig.fabrikkaVersion);
    this._validateFabricVersion(networkConfig.networkSettings.fabricVersion);

    this._validateOrdererCountForSoloType(networkConfig.rootOrg.orderer);
  }

  async summary() {
    this.log(chalk.bold('========== Validation summary =========='));
    this.log(`Errors count: ${this.listeners.error.count()}`);
    this.log(`Warnings count: ${this.listeners.warn.count()}`);

    this._printIfNotEmpty(this.listeners.error.messages, chalk.red.bold('Errors found :'));
    this._printIfNotEmpty(this.listeners.warn.messages, chalk.yellow('Warnings found :'));

    this.log(chalk.bold('========================================'));

    this.on('end', () => {
      this.removeAllListeners(validationErrorType.ERROR);
      this.removeAllListeners(validationErrorType.WARN);
    });
  }

  _printIfNotEmpty(messages, caption) {
    if (messages.length > 0) {
      this.log(caption);

      const grouped = this._groupBy(messages, (msg) => msg.category);

      Array.from(grouped.keys()).forEach((key) => {
        this.log(chalk.bold(`  ${key}:`));
        grouped.get(key).forEach((msg) => this.log(`   - ${msg.message}`));
      });
    }
  }

  _validateSupportedFabrikkaVersion(fabrikkaVersion) {
    if (!supportedFabrikkaVersions.includes(fabrikkaVersion)) {
      const objectToEmit = {
        category: validationCategories.CRITICAL,
        message: `Fabrikka's ${fabrikkaVersion} version is not supported. Supported versions are: ${supportedFabrikkaVersions}`,
      };
      this.emit(validationErrorType.CRITICAL, objectToEmit);
    }
  }

  _validateFabricVersion(fabricVersion) {
    if (!supportedFabricVersions.includes(fabricVersion)) {
      const objectToEmit = {
        category: validationCategories.GENERAL,
        message: `Fabric's ${fabricVersion} version is not supported. Supported versions are: ${supportedFabricVersions}`,
      };
      this.emit(validationErrorType.ERROR, objectToEmit);
    }
  }

  _validateOrdererCountForSoloType(orderer) {
    if (orderer.consensus === 'solo' && orderer.instances > 1) {
      const objectToEmit = {
        category: validationCategories.ORDERER,
        message: `Orderer consesus type is set to 'solo', but number of instances is ${orderer.instances}. Only 1 instance will be created.`,
      };
      this.emit(validationErrorType.WARN, objectToEmit);
    }
  }

  _getFullPathOf(configFile) {
    const currentPath = this.env.cwd;
    return `${currentPath}/${configFile}`;
  }

  static _groupBy(list, keyGetter) {
    const map = new Map();
    list.forEach((item) => {
      const key = keyGetter(item);
      const collection = map.get(key);
      if (!collection) {
        map.set(key, [item]);
      } else {
        collection.push(item);
      }
    });
    return map;
  }
};
