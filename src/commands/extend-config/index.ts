import { Args, Command } from "@oclif/core";
import * as fs from "fs-extra";
import * as path from "path";

import parseFabloConfig from "../../utils/parseFabloConfig";
import extendConfig from "./extendConfig";
import { getNetworkCapabilities } from "./extendGlobal";



export default class ExtendConfig extends Command {
  static override description = "Reads a Fablo config file, extends it, and prints the result";

  static override args = {
    config: Args.string({
      default: "../../network/fablo-config.json",
      description: "Fablo config file path",
      required: false,
    }),
  };
  async writing (args: { config?: string }): Promise<void> {
    const configPath = args?.config ?? "../../network/fablo-config.json";
    const fabloConfigPath = path.isAbsolute(configPath) ? configPath : path.join(process.cwd(), configPath);
    const json = parseFabloConfig(fs.readFileSync(fabloConfigPath).toString());
    const configExtended = extendConfig(json);
    this.log(JSON.stringify(configExtended, undefined, 2));
  }
  public async run(): Promise<void> {
    const { args } = await this.parse(ExtendConfig);
    await this.writing(args);

  }
  
}

export { extendConfig, getNetworkCapabilities };

