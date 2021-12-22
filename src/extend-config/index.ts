import * as Generator from "yeoman-generator";
import parseFabloConfig from "../utils/parseFabloConfig";
import extendConfig from "./extendConfig";
import { getNetworkCapabilities } from "./extendGlobal";

const ValidateGeneratorPath = require.resolve("../validate");

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
    const configExtended = extendConfig(json);
    this.log(JSON.stringify(configExtended, undefined, 2));
  }
}

export { extendConfig, getNetworkCapabilities };
export default ExtendConfigGenerator;
