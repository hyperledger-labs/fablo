import * as Generator from "yeoman-generator";
import parseFabloConfig from "../utils/parseFabloConfig";
import extendConfig from "../extend-config/extendConfig";
import { generateMermaidDiagram } from "./generateMermaidDiagram";
import { FabloConfigExtended } from "../types/FabloConfigExtended";
import * as fs from "fs";

class ExportNetworkTopologyGenerator extends Generator {
  private fabloConfigPath: string;
  private outputFile: string;

  constructor(args: string[], opts: Generator.GeneratorOptions) {
    super(args, opts);
    this.argument("fabloConfig", {
      type: String,
      optional: true,
      description: "Fablo config file path",
      default: "fablo-config.json",
    });
    this.argument("outputFile", {
      type: String,
      optional: true,
      description: "Output Mermaid file path",
      default: "network-topology.mmd",
    });

    const arg0 = this.options.fabloConfig;
    const arg1 = this.options.outputFile;
    if (arg1 && arg1 !== "network-topology.mmd") {
      this.fabloConfigPath = arg0;
      this.outputFile = arg1;
    } else if (arg0 && (arg0.endsWith(".json") || arg0.endsWith(".yaml") || arg0.endsWith(".yml"))) {
      this.fabloConfigPath = arg0;
      this.outputFile = "network-topology.mmd";
    } else {
      this.fabloConfigPath = "fablo-config.json";
      this.outputFile = arg0 || "network-topology.mmd";
    }
  }

  async writing(): Promise<void> {
    const json = parseFabloConfig(this.fs.read(this.fabloConfigPath));
    const configExtended: FabloConfigExtended = extendConfig(json);
    const mermaidDiagram = generateMermaidDiagram(configExtended);
    fs.writeFileSync(this.outputFile, mermaidDiagram);
    this.log(`✅ Network topology exported to ${this.outputFile}`);
  }
}

export default ExportNetworkTopologyGenerator;
