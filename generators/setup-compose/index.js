/*
 * License-Identifier: Apache-2.0
 */

const Generator = require('yeoman-generator');
const utils = require('../utils');
const mkdirp = require('mkdirp');

const configTransformers = require('./configTransformers');
const validationFunctions = require('./validationFunctions');

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

        const configFilePath = this._getFullPathOf(this.options.fabrikkaConfig);
        const fileExists = this.fs.exists(configFilePath);

        if (!fileExists) {
            this.emit('error', new Error(`No file under path: ${configFilePath}`));
        } else {
            this.options.fabrikkaConfigPath = configFilePath;
        }
    }

    async writing() {
        const thisGenerator = this;
        const networkConfig = this.fs.readJSON(this.options.fabrikkaConfigPath);

        validationFunctions.validateFabrikkaVersion(networkConfig.fabrikkaVersion, this.emit);
        validationFunctions.validateFabricVersion(networkConfig.networkSettings.fabricVersion, this.emit);
        validationFunctions.validateOrderer(networkConfig.rootOrg.orderer, this.emit);

        this.log("Used network config: " + this.options.fabrikkaConfigPath);
        this.log("Fabric version is: " + networkConfig.networkSettings.fabricVersion);
        this.log("Generating docker-compose network...");

        const capabilities = this._getNetworkCapabilities(networkConfig.networkSettings.fabricVersion);
        const rootOrgTransformed = configTransformers.transformRootOrgConfig(networkConfig.rootOrg);

        // ======= fabric-config =======================================================================================
        this._copyRootOrgCryptoConfig(
            {
                rootOrg: rootOrgTransformed
            }
        );

        this._copyOrgCryptoConfig(networkConfig.orgs);
        this._copyConfigTx(
            {
                capabilities: capabilities,
                networkSettings: networkConfig.networkSettings,
                rootOrg: rootOrgTransformed,
                orgs: networkConfig.orgs,
            }
        );
        this._copyGitIgnore();

        // ======= fabric-compose ======================================================================================
        this._copyDockerComposeEnv(
            {
                networkSettings: networkConfig.networkSettings,
                orgs: networkConfig.orgs,
            }
        );
        this._copyDockerCompose(
            {
                networkSettings: networkConfig.networkSettings,
                rootOrg: rootOrgTransformed,
                orgs: networkConfig.orgs,
                chaincodes: networkConfig.chaincodes
            }
        );

        // ======= scripts =============================================================================================
        const channelsTransformed = networkConfig.channels.map(channel => configTransformers.transformChannelConfig(channel, networkConfig.orgs));
        const chaincodesTransformed = configTransformers.transformChaincodesConfig(networkConfig.chaincodes, channelsTransformed, this.env);

        this._copyCommandsGeneratedScript(
            {
                networkSettings: networkConfig.networkSettings,
                rootOrg: rootOrgTransformed,
                orgs: networkConfig.orgs,
                channels: channelsTransformed,
                chaincodes: chaincodesTransformed
            }
        );

        this._copyUtilityScripts();

        networkConfig.chaincodes.forEach(function (chaincode) {
            mkdirp.sync(chaincode.directory);
        });

        this.on('end', function () {
            chaincodesTransformed.filter(c => !c.chaincodePathExists).forEach(function (chaincode) {
                thisGenerator.log(`INFO: chaincode '${chaincode.name}' not found. Use generated folder and place it there.`);
            });
            this.log("Done & done !!! Try the network out: ");
            this.log("-> fabric-compose.sh up - to start network");
            this.log("-> fabric-compose.sh help - to view all commands");
        });
    }

    _copyConfigTx(settings) {
        this.fs.copyTpl(
            this.templatePath('fabric-config/configtx.yaml'),
            this.destinationPath('fabric-config/configtx.yaml'),
            settings,
        );
    }

    _copyGitIgnore() {
        this.fs.copyTpl(
            this.templatePath('fabric-config/.gitignore'),
            this.destinationPath('fabric-config/.gitignore')
        );
    }

    _copyRootOrgCryptoConfig(settings) {
        this.fs.copyTpl(
            this.templatePath('fabric-config/crypto-config-root.yaml'),
            this.destinationPath('fabric-config/crypto-config-root.yaml'),
            settings
        );
    }

    _copyOrgCryptoConfig(orgs) {
        const thisGenerator = this;
        orgs.forEach(function (org) {
            //TODO nazwa powinna byc wykorzystywana w commands-generated.sh.
            const orgsCryptoConfigFileName = `crypto-config-${org.organization.name.toLowerCase()}`;
            thisGenerator.fs.copyTpl(
                thisGenerator.templatePath('fabric-config/crypto-config-org.yaml'),
                thisGenerator.destinationPath(`fabric-config/${orgsCryptoConfigFileName}.yaml`),
                {org},
            );
        });
    }

    _copyDockerComposeEnv(settings) {
        this.fs.copyTpl(
            this.templatePath('fabric-compose/.env'),
            this.destinationPath('fabric-compose/.env'),
            settings,
        );
    }

    _copyDockerCompose(settings) {
        this.fs.copyTpl(
            this.templatePath('fabric-compose/docker-compose.yaml'),
            this.destinationPath('fabric-compose/docker-compose.yaml'),
            settings,
        )
    }

    _copyCommandsGeneratedScript(settings) {
        this.fs.copyTpl(
            this.templatePath('fabric-compose/scripts/commands-generated.sh'),
            this.destinationPath('fabric-compose/scripts/commands-generated.sh'),
            settings
        );
    }

    _copyUtilityScripts() {
        this.fs.copyTpl(
            this.templatePath('fabric-compose.sh'),
            this.destinationPath('fabric-compose.sh')
        );

        this.fs.copyTpl(
            this.templatePath('fabric-compose/scripts/cli/channel_fns.sh'),
            this.destinationPath('fabric-compose/scripts/cli/channel_fns.sh')
        );

        this.fs.copyTpl(
            this.templatePath('fabric-compose/scripts/cli/channel_fns.sh'),
            this.destinationPath('fabric-compose/scripts/cli/channel_fns.sh')
        );

        this.fs.copyTpl(
            this.templatePath('fabric-compose/scripts/base-functions.sh'),
            this.destinationPath('fabric-compose/scripts/base-functions.sh')
        );

        this.fs.copyTpl(
            this.templatePath('fabric-compose/scripts/base-help.sh'),
            this.destinationPath('fabric-compose/scripts/base-help.sh')
        );
    }

    _getNetworkCapabilities(fabricVersion) {
        switch (fabricVersion) {
            case '1.4.4':
                return {channel: "V1_4_3", orderer: "V1_4_2", application: "V1_4_2"};
            case '1.4.3':
                return {channel: "V1_4_3", orderer: "V1_4_2", application: "V1_4_2"};
            default:
                return {channel: "V1_4_3", orderer: "V1_4_2", application: "V1_4_2"};
        }
    }

    _getFullPathOf(configFile) {
        const currentPath = this.env.cwd;
        return currentPath + "/" + configFile;
    }

};
