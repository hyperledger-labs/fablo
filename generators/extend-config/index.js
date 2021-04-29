/*
* License-Identifier: Apache-2.0
*/
const Generator = require('yeoman-generator');
const configTransformers = require('./configTransformers');
const { parseFabricaConfig } = require('../utils/parseFabricaConfig');

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
    const json = parseFabricaConfig(this.fs.read(fabricaConfigPath));
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
  const networkSettings = configTransformers.transformNetworkSettings(networkSettingsJson);
  const chaincodes = configTransformers.transformChaincodesConfig(
    networkSettingsJson.fabricVersion, chaincodesJson, channels,
  );

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
