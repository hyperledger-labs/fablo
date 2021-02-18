/* eslint no-underscore-dangle: 0 */

/*
* License-Identifier: Apache-2.0
*/
const Generator = require('yeoman-generator');
const utils = require('../utils/utils');

const configTransformers = require('../setup-docker/configTransformers');

const ValidateGeneratorType = require.resolve('../validate');

module.exports = class extends Generator {
  constructor(args, opts) {
    super(args, opts);
    this.argument('fabricaConfig', {
      type: String,
      required: true,
      description: 'fabrica config file path',
    });

    this.composeWith(ValidateGeneratorType, { arguments: [this.options.fabricaConfig] });
  }

  async writing() {
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
    const networkSettings2 = configTransformers.transformNetworkSettings(networkSettings);

    const transformedConfig = {
      capabilities,
      rootOrg,
      orgs,
      channels,
      chaincodes,
      networkSettings2,
    };

    this.log(JSON.stringify(transformedConfig, null, 4));
  }
};
