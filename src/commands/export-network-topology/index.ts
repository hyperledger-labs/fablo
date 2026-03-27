import { Args, Command } from '@oclif/core'
import parseFabloConfig from "../../utils/parseFabloConfig";
import extendConfig from "../../extend-config/extendConfig";
import { generateMermaidDiagram } from "../../export-network-topology/generateMermaidDiagram";
import { FabloConfigExtended } from "../../types/FabloConfigExtended";
import * as fs from "fs";
import * as path from "path";

export default class ExportNetworkTopology extends Command {
  static override description = 'exports the network topology to a Mermaid file'
  private fabloConfigPath: string = "";
  private outputFile: string = "";

  static override args = {
    config: Args.string({
      description: "Fablo config file path. Defaults to fablo-config.json",
      required: false,
    }),
    output: Args.string({
      description: "(optional) Path to the output Mermaid file. Defaults to network-topology.mmd",
      required: false,
    }),

  }
  async writing(): Promise<void> {
    try {
      if (!fs.existsSync(this.fabloConfigPath)) {
        throw new Error(`Configuration file not found: ${this.fabloConfigPath}`);
      }

      const configContent = fs.readFileSync(this.fabloConfigPath, 'utf-8');
      if (!configContent) {
        throw new Error(`Failed to read configuration file: ${this.fabloConfigPath}`);
      }

      const json = parseFabloConfig(configContent);
      const configExtended: FabloConfigExtended = extendConfig(json);
      const mermaidDiagram = generateMermaidDiagram(configExtended);
      const outputDir = path.dirname(this.outputFile);
      if (!fs.existsSync(outputDir)) {
        fs.mkdirSync(outputDir, { recursive: true });
      }
      fs.writeFileSync(this.outputFile, mermaidDiagram);
      this.log(`✅ Network topology exported to ${this.outputFile}`);

    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : "An unknown error occurred";
      this.log(`❌ Error: ${errorMessage}`);
      throw error;
    }
  }

  public async run(): Promise<void> {
    const { args } = await this.parse(ExportNetworkTopology)

    let configArg = args.config;
    let outputArg = args.output;

    if (configArg && !outputArg) {
      if (configArg.endsWith('.mmd')) {
        outputArg = configArg;
        configArg = undefined;
      }
    }

    const finalConfig = configArg || 'fablo-config.json';
    const finalOutput = outputArg || 'network-topology.mmd';

    this.fabloConfigPath = path.isAbsolute(finalConfig) ? finalConfig : path.resolve(process.cwd(), finalConfig);
    this.outputFile = path.isAbsolute(finalOutput) ? finalOutput : path.resolve(process.cwd(), finalOutput);

    await this.writing();
  }
}
