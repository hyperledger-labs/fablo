import { Args, Command } from "@oclif/core";
import parseFabloConfig from "../utils/parseFabloConfig";
import * as fs from "fs";
import * as path from "path";
import SetupDocker from "../setup-docker/index";
import SetupK8s from "../setup-k8s/index";

export default class SetupNetwork extends Command {
  static override description = "Setup network files based on config (routes to docker or k8s)";

  static override args = {
    fabloConfig: Args.string({
      description: "Fablo config file path",
      required: false,
      default: "../../network/fablo-config.json",
    }),
  };

  public async run(): Promise<void> {
    const { args } = await this.parse(SetupNetwork);
    const configPath = args.fabloConfig ?? "../../network/fablo-config.json";
    const fabloConfigPath = path.isAbsolute(configPath) ? configPath : path.join(process.cwd(), configPath);

    if (!fs.existsSync(fabloConfigPath)) {
      this.error(`Config file not found: ${fabloConfigPath}`);
    }

    const configContent = fs.readFileSync(fabloConfigPath, "utf-8");
    const json = parseFabloConfig(configContent);

    if (json?.global?.engine === "kubernetes") {
      const k8sCommand = new SetupK8s(["--fabloConfig", fabloConfigPath], this.config);
      await k8sCommand.run();
    } else {
      const dockerCommand = new SetupDocker(["--fabloConfig", fabloConfigPath], this.config);
      await dockerCommand.run();
    }
  }
}

