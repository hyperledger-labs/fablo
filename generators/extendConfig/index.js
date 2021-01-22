/* eslint no-underscore-dangle: 0 */

/*
* License-Identifier: Apache-2.0
*/
const Generator = require('yeoman-generator');
const utils = require('../utils/utils');

const configTransformers = require('./configTransformers');

const ValidateGeneratorType = require.resolve('../validate');

module.exports = class extends Generator {
  constructor(args, opts) {
    super(args, opts);
    this.argument('fabricaConfig', {
      type: String,
      required: true,
      description: 'fabrica config file path',
    });
    this.option('debug', {
      alias: 'd',
    });

    this.composeWith(ValidateGeneratorType, { arguments: [this.options.fabricaConfig] });
  }

  async transformConfig() {
    this.options.fabricaConfigPath = utils.getFullPathOf(
      this.options.fabricaConfig, this.env.cwd,
    );

    const {
      networkSettings,
      rootOrg: rootOrgJson,
      orgs: orgsJson,
      channels: channelsJson,
      chaincodes: chaincodesJson,
    } = this.fs.readJSON(this.options.fabricaConfigPath);

    const capabilities = configTransformers.getNetworkCapabilities(networkSettings.fabricVersion);
    const rootOrg = configTransformers.transformRootOrgConfig(rootOrgJson);
    const orgs = configTransformers.transformOrgConfigs(orgsJson);
    const channels = configTransformers.transformChannelConfigs(channelsJson, orgs);
    const chaincodes = configTransformers.transformChaincodesConfig(chaincodesJson, channels);

    const transformedConfig = {
      networkSettings,
      capabilities,
      rootOrg,
      orgs,
      channels,
      chaincodes,
    };

    this.config.set('transformedConfig', transformedConfig);

    this.on('end', () => {
      if (typeof this.options.debug !== 'undefined') {
        this.log(JSON.stringify(this.config.get('transformedConfig'), null, 4));
      }
    });
  }
};
