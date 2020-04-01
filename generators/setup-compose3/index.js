/*
 * License-Identifier: Apache-2.0
 */

const Generator = require('yeoman-generator');
const utils = require('../utils');

const supportedFabricVersions = ['1.4.3', '1.4.4'];
const supportFabrikkaVersions = ['alpha-0.0.1'];

module.exports = class extends Generator {

    async initializing() {
        this.log(utils.splashScreen());
    }

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
        this._validateOrderer(networkConfig.rootOrg.orderer);

        this.log("Used network config: " + this.options.fabrikkaConfigPath);
        this.log("Fabric version is: " + networkConfig.networkSettings.fabricVersion);
        this.log("Generating docker-compose network...");

        const capabilities = this._getNetworkCapabilities(networkConfig.networkSettings.fabricVersion);

        this.fs.copyTpl(
            this.templatePath('fabric-config/crypto-config-root.yaml'),
            this.destinationPath('fabric-config/crypto-config-root.yaml'),
            {rootOrg: networkConfig.rootOrg}
        );

        const generator = this;
        networkConfig.orgs.forEach(function (org) {
            generator.fs.copyTpl(
                generator.templatePath('fabric-config/crypto-config-org.yaml'),
                generator.destinationPath(`fabric-config/crypto-config-${org.organization.name.toLowerCase()}.yaml`),
                {org},
            );
        });

        this.fs.copyTpl(
            this.templatePath('fabric-config/configtx.yaml'),
            this.destinationPath('fabric-config/configtx.yaml'),
            {
                capabilities: capabilities,
                networkSettings: networkConfig.networkSettings,
                rootOrg: networkConfig.rootOrg,
                orgs: networkConfig.orgs,
            },
        );

        this.fs.copyTpl(
            this.templatePath('fabric-compose/.env'),
            this.destinationPath('fabric-compose/.env'),
            {
                networkSettings: networkConfig.networkSettings,
                orgs: networkConfig.orgs,
            },
        );

        this.fs.copyTpl(
            this.templatePath('fabric-compose/docker-compose.yaml'),
            this.destinationPath('fabric-compose/docker-compose.yaml'),
            {
                networkSettings: networkConfig.networkSettings,
                rootOrg: networkConfig.rootOrg,
                orgs: networkConfig.orgs,
            },
        );

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

    _validateOrderer(orderer) {
        this._validationBase(
            (orderer.consensus === "solo" && orderer.instances > 1),
            `Orderer consesus type is set to 'solo', but number of instances is ${orderer.instances}. Only one instance is needed :).`
        )
    }

    _getNetworkCapabilities(fabricVersion) {
        switch (fabricVersion) {
            case '1.4.3':
                return {channel: "V1_4_3", orderer: "V1_4_2", application: "V1_4_2"};
            default:
                return {channel: "V1_4_2", orderer: "V1_4_2", application: "V1_4_2"};
        }
    }

    _getConfigsFullPath(configFile) {
        const currentPath = this.env.cwd;
        return currentPath + "/" + configFile;
    }

    _validationBase(condition, errorMessage) {
        if (condition) {
            this.emit('error', new Error(errorMessage));
        }
    }
};
