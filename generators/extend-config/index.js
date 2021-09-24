import * as Generator from "yeoman-generator";
import * as configTransformers from "./configTransformers";
import parseFabricaConfig from "../utils/parseFabricaConfig";
import { FabricaConfigJson } from "../types/FabricaConfigJson";
import { FabricaConfigExtended } from "../types/FabricaConfigExtended";

const ValidateGeneratorPath = require.resolve("../validate");

const extendConfig = (json: FabricaConfigJson): FabricaConfigExtended => {
  const {
    networkSettings: networkSettingsJson,
    rootOrg: rootOrgJson,
    orgs: orgsJson,
    channels: channelsJson,
    chaincodes: chaincodesJson,
  } = json;

  const capabilities = configTransformers.getNetworkCapabilities(networkSettingsJson.fabricVersion);
  const rootOrg = configTransformers.transformRootOrgConfig(rootOrgJson);
  const orgs = configTransformers.transformOrgConfigs(orgsJson, networkSettingsJson.tls);
  const channels = configTransformers.transformChannelConfigs(channelsJson, orgs);
  const networkSettings = configTransformers.transformNetworkSettings(networkSettingsJson);
  const chaincodes = configTransformers.transformChaincodesConfig(
    networkSettingsJson.fabricVersion,
    chaincodesJson,
    channels,
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

class ExtendConfigGenerator extends Generator {
  constructor(args: string[], opts: Generator.GeneratorOptions) {
    super(args, opts);
    this.argument("fabricaConfig", {
      type: String,
      required: true,
      description: "fabrica config file path",
    });

    this.composeWith(ValidateGeneratorPath, { arguments: [this.options.fabricaConfig] });
  }

  async writing(): Promise<void> {
    const fabricaConfigPath = `${this.env.cwd}/${this.options.fabricaConfig}`;
    const json = parseFabricaConfig(this.fs.read(fabricaConfigPath));
    const transformedConfig = extendConfig(json);
    this.log(JSON.stringify(transformedConfig, undefined, 2));
  }
}

export { extendConfig };
export default ExtendConfigGenerator;
