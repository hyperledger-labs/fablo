import { Args, Command, Flags } from "@oclif/core";
import * as path from "path";
import * as fs from "fs-extra";
import parseFabloConfig from "../../utils/parseFabloConfig";
import { ConnectService } from "../../services/connect/connectService";

export default class Connect extends Command {
  static override description = "Connect a peer from this Fablo instance to an existing Fabric network";

  static override args = {
    fabloConfig: Args.string({
      description: "Fablo config file path",
      required: false,
      default: "fablo-config.json",
    }),
  };

  static override flags = {
    verbose: Flags.boolean({
      char: "v",
      description: "Enable verbose output",
      default: false,
    }),
    "network-name": Flags.string({
      description: "Override docker network name",
      required: false,
    }),
  };

  public async run(): Promise<void> {
    try {
      const { args, flags } = await this.parse(Connect);
      
      const configPath = args.fabloConfig ?? "fablo-config.json";
      const fabloConfigPath = path.isAbsolute(configPath) ? configPath : path.join(process.cwd(), configPath);

      if (!fs.existsSync(fabloConfigPath)) {
        this.error(`Config file not found: ${fabloConfigPath}`);
      }

      this.log(`Loading config from: ${fabloConfigPath}`);
      const configContent = fs.readFileSync(fabloConfigPath, "utf-8");
      const fabloConfig = parseFabloConfig(configContent);

      if (!fabloConfig.externalNetwork) {
        this.error("externalNetwork configuration is missing in fablo-config.json");
      }

      const connectService = new ConnectService(fabloConfig, process.cwd(), {
        verbose: flags.verbose,
        networkNameOverride: flags["network-name"],
        logger: this.log.bind(this),
        errorLogger: this.error.bind(this),
      });

      this.log("Connecting to external Fabric network...");
      await connectService.connect();
      
      this.log("Successfully connected to the Fabric network!");
    } catch (error) {
      this.error(`Error: ${(error as Error).message}`);
    }
  }
}
