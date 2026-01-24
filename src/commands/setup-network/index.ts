import { Args, Command } from "@oclif/core";
import parseFabloConfig from "../../utils/parseFabloConfig";
import * as fs from "fs";
import * as path from "path";
import SetupDocker from "../../setup-docker/index";
import SetupK8s from "../../setup-k8s/index";
import { execSync } from 'child_process'
export default class SetupNetwork extends Command {
  static override description = "Setup network files based on config (routes to docker or k8s)";

  static override args = {
    fabloConfig: Args.string({
      description: "Fablo config file path",
      required: false,
      default: "fablo-config.json",
    }),
  };

  public async run(): Promise<void> {
    try {
      const { args } = await this.parse(SetupNetwork);
      this.log("Setting up network based on config:", args.fabloConfig);
      this.log("Current working directory:", process.cwd());
      const configPath = args.fabloConfig ?? "fablo-config.json";
      this.log("CLI config:", configPath);

      const fabloConfigPath = path.isAbsolute(configPath) ? configPath : path.join(process.cwd(), configPath);
      const output = execSync(`ls -alR`, { encoding: 'utf-8' })
      this.log("this output:", output);
      this.log("Resolved fablo config path:", fabloConfigPath);


      if (!fs.existsSync(fabloConfigPath)) {
        this.error('config path is: ', configPath as any);
        this.error(`Config file not found:pla pla ${fabloConfigPath}`);
      }

      const configContent = fs.readFileSync(fabloConfigPath, "utf-8");
      const json = parseFabloConfig(configContent);

      if (json?.global?.engine === "kubernetes") {
        const k8sCommand = new SetupK8s([fabloConfigPath], this.config);
        await k8sCommand.run();
      } else {
        const dockerCommand = new SetupDocker([fabloConfigPath], this.config);
        await dockerCommand.run();
      }
    } catch (error) {
      this.log(error as string );
      this.error(`Error setting up network: ${(error as Error).message}`);
    }
  }
}