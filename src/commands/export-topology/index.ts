import { Args, Command } from '@oclif/core'
import parseFabloConfig from "../../utils/parseFabloConfig";
import extendConfig from "../../extend-config/extendConfig";
import { generateMermaidDiagram } from "../../export-network-topology/generateMermaidDiagram";
import { FabloConfigExtended } from "../../types/FabloConfigExtended";
import * as fs from "fs";
import * as path from "path";

export default class ExportNetworkTopology extends Command {
  static override description = 'export-network-topology '
  private fabloConfigPath: string = "";
  private outputFile: string = "";

  static override args = {
    config: Args.string({ description: "Fablo config file path", 
      required: false, 
      default: 'fablo-config.json'
    }),
    output: Args.string({ description: "Output Mermaid file path", 
      required: false, 
      default: 'network-topology.mmd' 
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
    const arg0 = args.config!;
    const arg1 = args.output!;

    this.fabloConfigPath = path.isAbsolute(arg0) ? arg0 : path.resolve(process.cwd(), arg0);
    this.outputFile = path.isAbsolute(arg1) ? arg1 : path.resolve(process.cwd(), arg1);

    await this.writing();
  }
}
