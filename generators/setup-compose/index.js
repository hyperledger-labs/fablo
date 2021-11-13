/* eslint no-underscore-dangle: 0 */

/*
* License-Identifier: Apache-2.0
*/
const Generator = require('yeoman-generator');
const mkdirp = require('mkdirp');
const config = require('../config');
const utils = require('../utils/utils');

const configTransformers = require('./configTransformers');

const ValidateGeneratorType = require.resolve('../validate');

module.exports = class extends Generator {
  constructor(args, opts) {
    super(args, opts);
    this.argument('fabrikkaConfig', {
      type: String,
      required: true,
      description: 'fabrikka config file path',
    });

    this.composeWith(ValidateGeneratorType, { arguments: [this.options.fabrikkaConfig] });
  }

  initializing() {
    this.log(config.splashScreen());
  }

  async writing() {
    this.options.fabrikkaConfigPath = utils.getFullPathOf(
      this.options.fabrikkaConfig, this.env.cwd,
    );
    const networkConfig = this.fs.readJSON(this.options.fabrikkaConfigPath);

    this.log(`Used network config: ${this.options.fabrikkaConfigPath}`);
    this.log(`Fabric version is: ${networkConfig.networkSettings.fabricVersion}`);
    this.log('Generating docker-compose network...');

    const capabilities = configTransformers.getNetworkCapabilities(
      networkConfig.networkSettings.fabricVersion,
    );
    const rootOrgTransformed = configTransformers.transformRootOrgConfig(networkConfig.rootOrg);
    const orgsTransformed = networkConfig.orgs.map(configTransformers.transformOrgConfig);
    const channelsTransformed = networkConfig.channels.map(
      (channel) => configTransformers.transformChannelConfig(channel, networkConfig.orgs),
    );
    const chaincodesTransformed = configTransformers.transformChaincodesConfig(
      networkConfig.chaincodes, channelsTransformed, this.env,
    );

    // ======= fabric-config ============================================================
    this._copyRootOrgCryptoConfig(
      {
        rootOrg: rootOrgTransformed,
      },
    );

    this._copyOrgCryptoConfig(orgsTransformed);
    this._copyConfigTx(
      {
        capabilities,
        networkSettings: networkConfig.networkSettings,
        rootOrg: rootOrgTransformed,
        orgs: orgsTransformed,
      },
    );
    this._copyGitIgnore();

    // ======= fabric-compose ===========================================================
    this._copyDockerComposeEnv(
      {
        networkSettings: networkConfig.networkSettings,
        orgs: orgsTransformed,
      },
    );
    this._copyDockerCompose(
      {
        networkSettings: networkConfig.networkSettings,
        rootOrg: rootOrgTransformed,
        orgs: networkConfig.orgs,
        chaincodes: networkConfig.chaincodes,
      },
    );

    // ======= scripts ==================================================================
    this._copyCommandsGeneratedScript(
      {
        networkSettings: networkConfig.networkSettings,
        rootOrg: rootOrgTransformed,
        orgs: orgsTransformed,
        channels: channelsTransformed,
        chaincodes: chaincodesTransformed,
      },
    );

    this._copyUtilityScripts();

    networkConfig.chaincodes.forEach((chaincode) => {
      mkdirp.sync(chaincode.directory);
    });

    this.on('end', () => {
      chaincodesTransformed.filter((c) => !c.chaincodePathExists).forEach((chaincode) => {
        this.log(`INFO: chaincode '${chaincode.name}' not found. Use generated folder and place it there.`);
      });
      this.log('Done & done !!! Try the network out: ');
      this.log('-> fabric-compose.sh up - to start network');
      this.log('-> fabric-compose.sh help - to view all commands');
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
      this.destinationPath('fabric-config/.gitignore'),
    );
  }

  _copyRootOrgCryptoConfig(settings) {
    this.fs.copyTpl(
      this.templatePath('fabric-config/crypto-config-root.yaml'),
      this.destinationPath('fabric-config/crypto-config-root.yaml'),
      settings,
    );
  }

  _copyOrgCryptoConfig(orgsTransformed) {
    const thisGenerator = this;
    orgsTransformed.forEach((orgTransformed) => {
      thisGenerator.fs.copyTpl(
        thisGenerator.templatePath('fabric-config/crypto-config-org.yaml'),
        thisGenerator.destinationPath(`fabric-config/${orgTransformed.cryptoConfigFileName}.yaml`),
        { org: orgTransformed },
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
    );
  }

  _copyCommandsGeneratedScript(settings) {
    this.fs.copyTpl(
      this.templatePath('fabric-compose/commands-generated.sh'),
      this.destinationPath('fabric-compose/commands-generated.sh'),
      settings,
    );
  }

  _copyUtilityScripts() {
    this.fs.copyTpl(
      this.templatePath('fabric-compose.sh'),
      this.destinationPath('fabric-compose.sh'),
    );

    this.fs.copyTpl(
      this.templatePath('fabric-compose/scripts/cli/channel_fns.sh'),
      this.destinationPath('fabric-compose/scripts/cli/channel_fns.sh'),
    );

    this.fs.copyTpl(
      this.templatePath('fabric-compose/scripts/cli/channel_fns.sh'),
      this.destinationPath('fabric-compose/scripts/cli/channel_fns.sh'),
    );

    this.fs.copyTpl(
      this.templatePath('fabric-compose/scripts/base-functions.sh'),
      this.destinationPath('fabric-compose/scripts/base-functions.sh'),
    );

    this.fs.copyTpl(
      this.templatePath('fabric-compose/scripts/base-help.sh'),
      this.destinationPath('fabric-compose/scripts/base-help.sh'),
    );
  }

  _getFullPathOf(configFile) {
    const currentPath = this.env.cwd;
    return `${currentPath}/${configFile}`;
  }

  _displayHelp() {
    this.log('helpful help for this command !');
  }
};
