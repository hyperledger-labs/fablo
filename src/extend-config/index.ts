import * as Generator from "yeoman-generator";
import * as configTransformers from "./configTransformers";
import parseFabloConfig from "../utils/parseFabloConfig";
import { FabloConfigJson } from "../types/FabloConfigJson";
import { FabloConfigExtended } from "../types/FabloConfigExtended";

const ValidateGeneratorPath = require.resolve("../validate");

const extendConfig = (json: FabloConfigJson): FabloConfigExtended => {
  const {
    networkSettings: networkSettingsJson,
    rootOrg: rootOrgJson,
    orgs: orgsJson,
    channels: channelsJson,
    chaincodes: chaincodesJson,
  } = json;

  const networkSettings = configTransformers.transformNetworkSettings(networkSettingsJson);
  const capabilities = configTransformers.getNetworkCapabilities(networkSettings.fabricVersion);
  const rootOrg = configTransformers.transformRootOrgConfig(rootOrgJson);
  const orgs = configTransformers.transformOrgConfigs(orgsJson, networkSettings);
  const channels = configTransformers.transformChannelConfigs(channelsJson, orgs);
  const chaincodes = configTransformers.transformChaincodesConfig(
    networkSettings.fabricVersion,
    chaincodesJson,
    channels,
    capabilities,
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
    this.argument("fabloConfig", {
      type: String,
      optional: true,
      description: "Fablo config file path",
      default: "../../network/fablo-config.json",
    });

    this.composeWith(ValidateGeneratorPath, { arguments: [this.options.fabloConfig] });
  }

  async writing(): Promise<void> {
    const fabloConfigPath = `${this.env.cwd}/${this.options.fabloConfig}`;
    const json = parseFabloConfig(this.fs.read(fabloConfigPath));
    const transformedConfig = extendConfig(json);
    this.log(JSON.stringify(transformedConfig, undefined, 2));
  }
}

export { extendConfig };
export default ExtendConfigGenerator;
