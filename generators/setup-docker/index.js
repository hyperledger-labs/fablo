/* eslint no-underscore-dangle: 0 */

/*
* License-Identifier: Apache-2.0
*/
const Generator = require('yeoman-generator');
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

    const {
      networkSettings,
      rootOrg: rootOrgJson,
      orgs: orgsJson,
      channels: channelsJson,
      chaincodes: chaincodesJson,
    } = this.fs.readJSON(this.options.fabrikkaConfigPath);

    const dateString = new Date().toISOString().substring(0, 16).replace(/[^0-9]+/g, '-');
    const composeNetworkName = `fabrikka-network-${dateString}`;

    this.log(`Used network config: ${this.options.fabrikkaConfigPath}`);
    this.log(`Fabric version is: ${networkSettings.fabricVersion}`);
    this.log(`Generating docker-compose network '${composeNetworkName}'...`);

    const capabilities = configTransformers.getNetworkCapabilities(networkSettings.fabricVersion);
    const rootOrg = configTransformers.transformRootOrgConfig(rootOrgJson);
    const orgs = configTransformers.transformOrgConfigs(orgsJson);
    const channels = configTransformers.transformChannelConfigs(channelsJson, orgsJson);
    const chaincodes = configTransformers.transformChaincodesConfig(chaincodesJson, channels);

    // ======= fabric-config ============================================================
    this._copyRootOrgCryptoConfig(rootOrg);
    this._copyOrgCryptoConfig(orgs);
    this._copyConfigTx(capabilities, networkSettings, rootOrg, orgs);
    this._copyGitIgnore();

    // ======= fabric-docker ===========================================================
    this._copyDockerComposeEnv(networkSettings, orgs, composeNetworkName);
    this._copyDockerCompose({
      networkSettings, rootOrg, orgs: orgsJson, chaincodes, // FIXME
    });

    // ======= scripts ==================================================================
    this._copyCommandsGeneratedScript(networkSettings, rootOrg, orgs, channels, chaincodes);
    this._copyUtilityScripts();

    this.on('end', () => {
      this.log('Done & done !!! Try the network out: ');
      this.log('-> fabric-docker.sh up - to start network');
      this.log('-> fabric-docker.sh help - to view all commands');
    });
  }

  _copyConfigTx(capabilities, networkSettings, rootOrg, orgs) {
    const settings = {
      capabilities,
      isHlf20: configTransformers.isHlf20(networkSettings.fabricVersion),
      networkSettings,
      rootOrg,
      orgs,
    };
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

  _copyRootOrgCryptoConfig(rootOrg) {
    this.fs.copyTpl(
      this.templatePath('fabric-config/crypto-config-root.yaml'),
      this.destinationPath('fabric-config/crypto-config-root.yaml'),
      { rootOrg },
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

  _copyDockerComposeEnv(networkSettings, orgsTransformed, composeNetworkName) {
    const settings = {
      composeNetworkName,
      fabricCaVersion: configTransformers.getCaVersion(networkSettings.fabricVersion),
      networkSettings,
      orgs: orgsTransformed,
      paths: configTransformers.getPathsFromEnv(),
    };
    this.fs.copyTpl(
      this.templatePath('fabric-docker/.env'),
      this.destinationPath('fabric-docker/.env'),
      settings,
    );
  }

  _copyDockerCompose(settings) {
    this.fs.copyTpl(
      this.templatePath('fabric-docker/docker-compose.yaml'),
      this.destinationPath('fabric-docker/docker-compose.yaml'),
      settings,
    );
  }

  _copyCommandsGeneratedScript(networkSettings, rootOrg, orgs, channels, chaincodes) {
    const settings = {
      networkSettings,
      rootOrg,
      orgs,
      channels,
      chaincodes,
    };
    this.fs.copyTpl(
      this.templatePath('fabric-docker/commands-generated.sh'),
      this.destinationPath('fabric-docker/commands-generated.sh'),
      settings,
    );
  }

  _copyUtilityScripts() {
    this.fs.copyTpl(
      this.templatePath('fabric-docker.sh'),
      this.destinationPath('fabric-docker.sh'),
    );

    this.fs.copyTpl(
      this.templatePath('fabric-docker/scripts/cli/channel_fns.sh'),
      this.destinationPath('fabric-docker/scripts/cli/channel_fns.sh'),
    );

    this.fs.copyTpl(
      this.templatePath('fabric-docker/scripts/cli/channel_fns.sh'),
      this.destinationPath('fabric-docker/scripts/cli/channel_fns.sh'),
    );

    this.fs.copyTpl(
      this.templatePath('fabric-docker/scripts/base-functions.sh'),
      this.destinationPath('fabric-docker/scripts/base-functions.sh'),
    );

    this.fs.copyTpl(
      this.templatePath('fabric-docker/scripts/base-help.sh'),
      this.destinationPath('fabric-docker/scripts/base-help.sh'),
    );

    this.fs.copyTpl(
      this.templatePath('fabric-docker/scripts/chaincode-functions.sh'),
      this.destinationPath('fabric-docker/scripts/chaincode-functions.sh'),
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
