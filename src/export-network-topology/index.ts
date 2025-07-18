import * as Generator from "yeoman-generator";
import parseFabloConfig from "../utils/parseFabloConfig";
import extendConfig from "../extend-config/extendConfig";
import { generateMermaidDiagram } from "./generateMermaidDiagram";
import { FabloConfigExtended } from "../types/FabloConfigExtended";
import * as fs from "fs";
import * as path from "path";

class ExportNetworkTopologyGenerator extends Generator {
  private fabloConfigPath: string;
  private outputFile: string;

  constructor(args: string[], opts: Generator.GeneratorOptions) {
    super(args, opts);
    this.argument("fabloConfig", {
      type: String,
      optional: true,
      description: "Fablo config file path",
      default: "/network/fablo-config.json",
    });
    this.argument("outputFile", {
      type: String,
      optional: true,
      description: "Output Mermaid file path",
      default: "network-topology.mmd",
    });

    const arg0 = this.options.fabloConfig;
    const arg1 = this.options.outputFile;

    this.fabloConfigPath = path.isAbsolute(arg0) ? arg0 : path.resolve(process.cwd(), arg0);
    this.outputFile = path.isAbsolute(arg1) ? arg1 : path.resolve(process.cwd(), arg1);
  }

  async writing(): Promise<void> {
    try {
      if (!fs.existsSync(this.fabloConfigPath)) {
        throw new Error(`Configuration file not found: ${this.fabloConfigPath}`);
      }

      const configContent = this.fs.read(this.fabloConfigPath);
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
    } catch (err: unknown) {
      const errorMessage = err instanceof Error ? err.message : "An unknown error occurred";
      this.log(`❌ Error: ${errorMessage}`);
      throw err;
    }
  }
}

export default ExportNetworkTopologyGenerator;
