import { Args, Command } from "@oclif/core";
import parseFabloConfig from "../utils/parseFabloConfig";
import { FabloConfigExtended, HooksConfig } from "../types/FabloConfigExtended";
import { extendConfig } from "../commands/extend-config/";
import * as fs from "fs-extra";
import * as path from "path";
import { renderTemplate, getTemplatePath, getDestinationPath } from "../utils/templateUtils";
import { DEFAULT_FABRICNETWORK_NAME, toFabricOpsYaml } from "./fabricOpsManifest";

export default class SetupK8s extends Command {
  static override description = "Setup Kubernetes network files from Fablo config";

  static override args = {
    fabloConfig: Args.string({
      description: "Fablo config file path",
      required: false,
      default: "fablo-config.json",
    }),
  };

  private outputDir: string = process.cwd();
  private templatesDir: string = path.join(__dirname, "./templates");

  public async run(): Promise<void> {
    const { args } = await this.parse(SetupK8s);
    const configPath = args.fabloConfig ?? "fablo-config.json";
    const fabloConfigPath = path.isAbsolute(configPath) ? configPath : path.join(process.cwd(), configPath);

    // Validate config first - we'll validate in the writing method
    // Note: Full validation should be done before calling this command

    await this.writing(fabloConfigPath);
  }

  async writing(fabloConfigPath: string): Promise<void> {
    const configContent = await fs.readFile(fabloConfigPath, "utf-8");
    const json = parseFabloConfig(configContent);
    const configExtended = extendConfig(json);
    const { global } = configExtended;

    this.log(`Used network config: ${fabloConfigPath}`);
    this.log(`Fabric version is: ${global.fabricVersion}`);
    this.log("Generating FabricOps Kubernetes manifest...");

    await this._copyGitIgnore();

    // ======= fabric-k8s ==============================================================
    await this._createFabricOpsManifest(json, configExtended);
    await this._copyFabricK8sScript(configExtended);

    // ======= hooks ====================================================================
    await this._copyHooks(configExtended.hooks);

    // generate the diagram by default
    const outputFile = getDestinationPath(this.outputDir, "network-topology.mmd");
    // Import and use the export topology logic directly
    const { generateMermaidDiagram } = await import("../export-network-topology/generateMermaidDiagram");
    const mermaidDiagram = generateMermaidDiagram(configExtended);
    await fs.ensureDir(path.dirname(outputFile));
    await fs.writeFile(outputFile, mermaidDiagram, "utf-8");
    this.log(`✅ Network topology exported to ${outputFile}`);

    this.log("Done & done !!! Try the network out: ");
    this.log("-> fablo up - to apply the FabricOps network");
    this.log("-> fablo help - to view all commands");
  }

  async _copyGitIgnore(): Promise<void> {
    const templatePath = getTemplatePath(this.templatesDir, "fabric-config/.gitignore");
    const destPath = getDestinationPath(this.outputDir, "fabric-config/.gitignore");
    await renderTemplate(templatePath, destPath, {});
  }

  async _createFabricOpsManifest(
    json: ReturnType<typeof parseFabloConfig>,
    config: FabloConfigExtended,
  ): Promise<void> {
    const destPath = getDestinationPath(this.outputDir, "fabric-k8s/fabricnetwork.yaml");
    await fs.ensureDir(path.dirname(destPath));
    await fs.writeFile(destPath, toFabricOpsYaml(json, config), "utf-8");
  }

  async _copyFabricK8sScript(config: FabloConfigExtended): Promise<void> {
    const fabricK8sShTemplate = getTemplatePath(this.templatesDir, "fabric-k8s.sh");
    const fabricK8sShDest = getDestinationPath(this.outputDir, "fabric-k8s.sh");
    await renderTemplate(fabricK8sShTemplate, fabricK8sShDest, {
      ...config,
      fabricNetworkName: DEFAULT_FABRICNETWORK_NAME,
    } as unknown as Record<string, unknown>);
  }

  async _copyHooks(hooks: HooksConfig): Promise<void> {
    const hooksFiles = ["hooks/post-generate.sh", "hooks/post-start.sh"];
    for (const hookFile of hooksFiles) {
      const templatePath = getTemplatePath(this.templatesDir, hookFile);
      const destPath = getDestinationPath(this.outputDir, hookFile);
      await renderTemplate(templatePath, destPath, { hooks });
    }
  }
}
