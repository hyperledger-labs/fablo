import { Args, Command } from "@oclif/core";
import * as config from "../config";
import { getBuildInfo } from "../version/buildUtil";
import parseFabloConfig from "../utils/parseFabloConfig";
import { Capabilities, FabloConfigExtended, HooksConfig, Global, OrgConfig } from "../types/FabloConfigExtended";
import { extendConfig } from "../commands/extend-config/";
import * as fs from "fs-extra";
import * as path from "path";
import { renderTemplate, getTemplatePath, getDestinationPath } from "../utils/templateUtils";

export default class SetupK8s extends Command {
  static override description = "Setup Kubernetes network files from Fablo config";

  static override args = {
    fabloConfig: Args.string({
      description: "Fablo config file path",
      required: false,
      default: "../../network/fablo-config.json",
    }),
  };

  private outputDir: string = process.cwd();
  private templatesDir: string = path.join(__dirname, "./templates");

  public async run(): Promise<void> {
    const { args } = await this.parse(SetupK8s);
    const configPath = args.fabloConfig ?? "../../network/fablo-config.json";
    const fabloConfigPath = path.isAbsolute(configPath) ? configPath : path.join(process.cwd(), configPath);

    // Validate config first - we'll validate in the writing method
    // Note: Full validation should be done before calling this command

    await this.writing(fabloConfigPath);
  }

  async writing(fabloConfigPath: string): Promise<void> {
    const configContent = await fs.readFile(fabloConfigPath, "utf-8");
    const json = parseFabloConfig(configContent);
    const configExtended = extendConfig(json);
    const { global, orgs } = configExtended;

    const dateString = new Date()
      .toISOString()
      .substring(0, 16)
      .replace(/[^0-9]+/g, "");
    const composeNetworkName = `fablo_network_${dateString}`;

    this.log(`Used network config: ${fabloConfigPath}`);
    this.log(`Fabric version is: ${global.fabricVersion}`);

    await this._copyGitIgnore();

    // ======= fabric-k8s ===========================================================
    await this._copyEnvFile(global, orgs, composeNetworkName);

    // ======= scripts ==================================================================
    await this._copyCommandsGeneratedScript(configExtended);
    await this._copyUtilityScripts(configExtended.global.capabilities);

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
    this.log("-> fablo up - to start network");
    this.log("-> fablo help - to view all commands");
  }

  async _copyGitIgnore(): Promise<void> {
    const templatePath = getTemplatePath(this.templatesDir, "fabric-config/.gitignore");
    const destPath = getDestinationPath(this.outputDir, "fabric-config/.gitignore");
    await renderTemplate(templatePath, destPath, {});
  }

  async _copyEnvFile(global: Global, orgsTransformed: OrgConfig[], composeNetworkName: string): Promise<void> {
    const settings = {
      composeNetworkName,
      fabricCaVersion: global.fabricCaVersion,
      global,
      orgs: orgsTransformed,
      paths: global.paths,
      fabloVersion: config.fabloVersion,
      fabloBuild: getBuildInfo(),
      fabloRestVersion: "0.1.2",
      hyperledgerExplorerVersion: "1.1.8",
      fabricCouchDbVersion: "0.4.18",
      couchDbVersion: "3.1",
      fabricCaPostgresVersion: "14",
    };
    const templatePath = getTemplatePath(this.templatesDir, "fabric-k8s/.env");
    const destPath = getDestinationPath(this.outputDir, "fabric-k8s/.env");
    await renderTemplate(templatePath, destPath, settings);
  }

  async _copyCommandsGeneratedScript(config: FabloConfigExtended): Promise<void> {
    const templatePath = getTemplatePath(this.templatesDir, "fabric-k8s/scripts/base-functions.sh");
    const destPath = getDestinationPath(this.outputDir, "fabric-k8s/scripts/base-functions.sh");
    await renderTemplate(templatePath, destPath, config as unknown as Record<string, unknown>);
  }

  async _copyUtilityScripts(capabilities: Capabilities): Promise<void> {
    // Copy fabric-k8s.sh
    const fabricK8sShTemplate = getTemplatePath(this.templatesDir, "fabric-k8s.sh");
    const fabricK8sShDest = getDestinationPath(this.outputDir, "fabric-k8s.sh");
    await renderTemplate(fabricK8sShTemplate, fabricK8sShDest, {});

    // Copy base-help.sh
    const baseHelpTemplate = getTemplatePath(this.templatesDir, "fabric-k8s/scripts/base-help.sh");
    const baseHelpDest = getDestinationPath(this.outputDir, "fabric-k8s/scripts/base-help.sh");
    await renderTemplate(baseHelpTemplate, baseHelpDest, {});

    // Copy util.sh
    const utilTemplate = getTemplatePath(this.templatesDir, "fabric-k8s/scripts/util.sh");
    const utilDest = getDestinationPath(this.outputDir, "fabric-k8s/scripts/util.sh");
    await renderTemplate(utilTemplate, utilDest, {});

    // Copy chaincode-functions.sh (base)
    const chaincodeFunctionsBaseTemplate = getTemplatePath(this.templatesDir, "fabric-k8s/scripts/chaincode-functions.sh");
    const chaincodeFunctionsBaseDest = getDestinationPath(this.outputDir, "fabric-k8s/scripts/chaincode-functions.sh");
    await renderTemplate(chaincodeFunctionsBaseTemplate, chaincodeFunctionsBaseDest, {});

    // Copy chaincode-functions script (v2 or v1.4) - this overwrites the base
    const chaincodeFunctionsTemplate = getTemplatePath(
      this.templatesDir,
      `fabric-k8s/scripts/chaincode-functions-${capabilities.isV2 ? "v2" : "v1.4"}.sh`,
    );
    const chaincodeFunctionsDest = getDestinationPath(this.outputDir, "fabric-k8s/scripts/chaincode-functions.sh");
    await renderTemplate(chaincodeFunctionsTemplate, chaincodeFunctionsDest, {});
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

