/* eslint no-underscore-dangle: 0 */

/*
* License-Identifier: Apache-2.0
*/
const Generator = require('yeoman-generator');
const configTransformers = require('./configTransformers');

const ValidateGeneratorPath = require.resolve('../validate');

class ExtendConfigGenerator extends Generator {
  constructor(args, opts) {
    super(args, opts);
    this.argument('fabricaConfig', {
      type: String,
      required: true,
      description: 'fabrica config file path',
    });

    this.composeWith(ValidateGeneratorPath, { arguments: [this.options.fabricaConfig] });
  }

  async writing() {
    const fabricaConfigPath = `${this.env.cwd}/${this.options.fabricaConfig}`;
    const json = this.fs.readJSON(fabricaConfigPath);
    const transformedConfig = ExtendConfigGenerator.extendJsonConfig(json);
    this.log(JSON.stringify(transformedConfig, undefined, 2));
  }
}

ExtendConfigGenerator.extendJsonConfig = (json) => {
  const {
    networkSettings: networkSettingsJson,
    rootOrg: rootOrgJson,
    orgs: orgsJson,
    channels: channelsJson,
    chaincodes: chaincodesJson,
  } = json;

  const capabilities = configTransformers.getNetworkCapabilities(networkSettingsJson.fabricVersion);
  const rootOrg = configTransformers.transformRootOrgConfig(rootOrgJson);
  const orgs = configTransformers.transformOrgConfigs(orgsJson);
  const channels = configTransformers.transformChannelConfigs(channelsJson, orgs);
  const chaincodes = configTransformers.transformChaincodesConfig(chaincodesJson, channels);
  const networkSettings = configTransformers.transformNetworkSettings(networkSettingsJson);

  return {
    networkSettings,
    capabilities,
    rootOrg,
    orgs,
    channels,
    chaincodes,
  };
};

module.exports = ExtendConfigGenerator;
