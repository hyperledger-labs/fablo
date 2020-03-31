/*
 * License-Identifier: Apache-2.0
 */


const Generator = require('yeoman-generator');

const utils = require('../utils');

const supportedFabricVersions = ['1.4.3'];
const supportFabrikkaVersions = ['alpha-0.0.1'];

module.exports = class extends Generator {

    constructor(args, opts) {
        super(args, opts);
        this.argument("fabrikkaConfig", {
            type: String,
            required: true,
            description: "Name of fabrikka config file in current dir"
        });

        const configFilePath = this._getConfigsFullPath(this.options.fabrikkaConfig);
        const fileExists = this.fs.exists(configFilePath);

        if (!fileExists) {
            this.emit('error', new Error(`No file under path: ${configFilePath}`));
        } else {
            this.options.fabrikkaConfigPath = configFilePath;
        }
    }

    async writing() {
        const networkConfig = this.fs.readJSON(this.options.fabrikkaConfigPath);

        this._validateFabrikkaVersion(networkConfig.fabrikkaVersion);
        this._validateFabricVersion(networkConfig.networkSettings.fabricVersion);

        this.log("Fabric version is: "+ networkConfig.networkSettings.fabricVersion);
    }

    _validateFabrikkaVersion(fabrikkaVersion) {
        this._validationBase(
            !supportFabrikkaVersions.includes(fabrikkaVersion),
            `Fabrikka's ${fabrikkaVersion} version is not supported. Supported versions are: ${supportFabrikkaVersions}`
        );
    }

    _validateFabricVersion(fabricVersion) {
        this._validationBase(
            !supportedFabricVersions.includes(fabricVersion),
            `Fabric's ${fabricVersion} version is not supported. Supported versions are: ${supportedFabricVersions}`
        );
    }

    _getConfigsFullPath(configFile) {
        const currentPath = this.env.cwd;
        return currentPath + "/" + configFile;
    }

    _validationBase(condition, errorMessage) {
        if(condition) {
            this.emit('error', new Error(errorMessage));
        }
    }
};
