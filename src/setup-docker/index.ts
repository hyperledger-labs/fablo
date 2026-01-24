import { Args, Command } from "@oclif/core";
import * as config from "../config";
import * as yaml from "js-yaml";
import { getBuildInfo } from "../version/buildUtil";
import parseFabloConfig from "../utils/parseFabloConfig";
import {
  Capabilities,
  ChaincodeConfig,
  ChannelConfig,
  FabloConfigExtended,
  HooksConfig,
  Global,
  OrgConfig,
  OrdererGroup,
} from "../types/FabloConfigExtended";
import { extendConfig } from "../commands/extend-config";
import {
  createConnectionProfile,
  createExplorerConnectionProfile,
  pairOrgWithChannels,
} from "../types/ConnectionProfile";
import { createExplorerConfig } from "../types/ExplorerConfig";
import * as fs from "fs-extra";
import * as path from "path";
import { renderTemplate, getTemplatePath, getDestinationPath } from "../utils/templateUtils";

export default class SetupDocker extends Command {
  static override description = "Setup Docker network files from Fablo config";

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
    const { args } = await this.parse(SetupDocker);
    this.log("fablo config is: ", args.fabloConfig);
    const configPath = args.fabloConfig ?? "fablo-config.json";
    const fabloConfigPath = path.isAbsolute(configPath) ? configPath : path.join(process.cwd(), configPath);
    this.log("Resolved fablo config path:", fabloConfigPath);
    this.log(`pritn templates dir: ${this.templatesDir}`);
    this.log(`pritn output dir: ${this.outputDir}`);

    if (!fs.existsSync(fabloConfigPath)) {
      this.error(`Config file not found: ${fabloConfigPath}`);
    }
    // Validate config first - we'll validate in the writing method
    // Note: Full validation should be done before calling this command

    await this.writing(fabloConfigPath);
  }

  async writing(fabloConfigPath: string): Promise<void> {
    const configContent = await fs.readFile(fabloConfigPath, "utf-8");
    const json = parseFabloConfig(configContent);
    const configExtended = extendConfig(json);
    const { global, orgs, chaincodes, channels } = configExtended;

    const dateString = new Date()
      .toISOString()
      .substring(0, 16)
      .replace(/[^0-9]+/g, "");
    const composeNetworkName = `fablo_network_${dateString}`;

    this.log(`Used network config: ${fabloConfigPath}`);
    this.log(`Fablo version: 2.4.2`);
    this.log(`Fabric version is: ${global.fabricVersion}`);
    this.log(`Generating docker-compose network  pla pla pla '${composeNetworkName}'...`);

    // ======= fabric-config ============================================================
    await this._copyOrgCryptoConfig(orgs);
    await this._createConnectionProfiles(global, orgs, channels, configExtended.ordererGroups);
    await this._createFabricCaServerConfigs(orgs);
    await this._createExplorerMaterial(global, orgs, channels);
    await this._copyConfigTx(configExtended);
    await this._copyGitIgnore();
    await this._createPrivateDataCollectionConfigs(chaincodes);

    // ======= fabric-docker ===========================================================
    await this._copyDockerComposeEnv(global, orgs, composeNetworkName);
    await this._copyDockerCompose(configExtended);

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

  async _copyConfigTx(config: FabloConfigExtended): Promise<void> {
    const templatePath = getTemplatePath(this.templatesDir, "fabric-config/configtx.yaml");
    const destPath = getDestinationPath(this.outputDir, "fabric-config/configtx.yaml");
    await renderTemplate(templatePath, destPath, config as unknown as Record<string, unknown>);
  }

  async _copyGitIgnore(): Promise<void> {
    const templatePath = getTemplatePath(this.templatesDir, "fabric-config/.gitignore");
    const destPath = getDestinationPath(this.outputDir, "fabric-config/.gitignore");
    await renderTemplate(templatePath, destPath, {});
  }

  async _copyOrgCryptoConfig(orgsTransformed: OrgConfig[]): Promise<void> {
    for (const orgTransformed of orgsTransformed) {
      const templatePath = getTemplatePath(this.templatesDir, "fabric-config/crypto-config-org.yaml");
      const destPath = getDestinationPath(this.outputDir, `fabric-config/${orgTransformed.cryptoConfigFileName}.yaml`);
      await renderTemplate(templatePath, destPath, { org: orgTransformed });
    }
  }

  async _createConnectionProfiles(
    global: Global,
    orgsTransformed: OrgConfig[],
    channels: ChannelConfig[],
    ordererGroups: OrdererGroup[],
  ): Promise<void> {
    for (const org of orgsTransformed) {
      const connectionProfile = createConnectionProfile(global, org, orgsTransformed, channels, ordererGroups);
      const orgName = org.name.toLowerCase();
      const jsonPath = getDestinationPath(this.outputDir, `fabric-config/connection-profiles/connection-profile-${orgName}.json`);
      const yamlPath = getDestinationPath(this.outputDir, `fabric-config/connection-profiles/connection-profile-${orgName}.yaml`);
      
      await fs.ensureDir(path.dirname(jsonPath));
      await fs.writeJSON(jsonPath, connectionProfile, { spaces: 2 });
      await fs.writeFile(yamlPath, yaml.dump(connectionProfile), "utf-8");
    }
  }

  async _createFabricCaServerConfigs(orgsTransformed: OrgConfig[]): Promise<void> {
    for (const orgTransformed of orgsTransformed) {
      const templatePath = getTemplatePath(this.templatesDir, "fabric-config/fabric-ca-server-config.yaml");
      const destPath = getDestinationPath(
        this.outputDir,
        `fabric-config/fabric-ca-server-config/${orgTransformed.domain}/fabric-ca-server-config.yaml`,
      );
      await renderTemplate(templatePath, destPath, { org: orgTransformed });
    }
  }

  // async _createExplorerMaterial(global: Global, orgsTransformed: OrgConfig[], channels: ChannelConfig[]): Promise<void> {
  //   try{
  //   const orgs = orgsTransformed.filter((o) => o.anchorPeers.length > 0);
  //   const orgWithChannels = pairOrgWithChannels(orgs, channels);

  //   for (const p of orgWithChannels) {
  //     if (global.tools.explorer !== undefined || p.org.tools.explorer !== undefined) {
  //       const connectionProfile = createExplorerConnectionProfile(global, p, orgsTransformed);
  //       const orgName = p.org.name.toLowerCase();
  //       const connectionProfilePath = getDestinationPath(
  //         this.outputDir,
  //         `fabric-config/explorer/connection-profile-${orgName}.json`,
  //       );
  //       this.log("connection profile path is: ", connectionProfilePath);
  //       this.log("Output dir: ",this.outputDir)
  //       const configPath = getDestinationPath(this.outputDir, `fabric-config/explorer/config-${orgName}.json`);
  //       await fs.ensureDir(path.dirname(connectionProfilePath));
  //       await fs.writeJSON(connectionProfilePath, connectionProfile, { spaces: 2 });
  //       await fs.writeJSON(configPath, createExplorerConfig([p.org]), { spaces: 2 });
  //     }
  //   }

  //   const globalConfigPath = getDestinationPath(this.outputDir, "fabric-config/explorer/config-global.json");
  //   if( !globalConfigPath){
  //     this.error("Error: Global config path is undefined");
  //   }
  //   await fs.writeJSON(globalConfigPath, createExplorerConfig(orgWithChannels.map((p) => p.org)), { spaces: 2 });
  // }catch(error: any){
  //   this.log("Error creating explorer material: ", error.message);
  //   this.error("Error creating explorer material: " + error.message);
  // }
  // }

  async _createExplorerMaterial(global: Global, orgsTransformed: OrgConfig[], channels: ChannelConfig[]): Promise<void> {
  try {
    // Create explorer directory first
    const explorerDir = getDestinationPath(this.outputDir, "fabric-config/explorer");
    await fs.ensureDir(explorerDir);

    if(!explorerDir){
      this.log("Error: Explorer directory path is undefined");
      return;
    }

    const orgs = orgsTransformed.filter((o) => o.anchorPeers.length > 0);
    const orgWithChannels = pairOrgWithChannels(orgs, channels);

    for (const p of orgWithChannels) {
      if (global.tools?.explorer !== undefined || p.org.tools?.explorer !== undefined) {
        const connectionProfile = createExplorerConnectionProfile(global, p, orgsTransformed);
        const orgName = p.org.name.toLowerCase();
        const connectionProfilePath = getDestinationPath(
          this.outputDir,
          `fabric-config/explorer/connection-profile-${orgName}.json`,
        );
        this.log("connection profile path is: ", connectionProfilePath);
        this.log("Output dir: ", this.outputDir);
        const configPath = getDestinationPath(this.outputDir, `fabric-config/explorer/config-${orgName}.json`);
        await fs.ensureDir(path.dirname(connectionProfilePath));
        await fs.writeJSON(connectionProfilePath, connectionProfile, { spaces: 2 });
        await fs.writeJSON(configPath, createExplorerConfig([p.org]), { spaces: 2 });
      }
    }

    const globalConfigPath = getDestinationPath(this.outputDir, "fabric-config/explorer/config-global.json");
    if (!globalConfigPath) {
      this.error("Error: Global config path is undefined");
    }
    await fs.writeJSON(globalConfigPath, createExplorerConfig(orgWithChannels.map((p) => p.org)), { spaces: 2 });
  } catch (error: any) {
    this.log("Error creating explorer material: ", error.message);
    this.error("Error creating explorer material: " + error.message);
  }
}
  async _copyDockerComposeEnv(global: Global, orgsTransformed: OrgConfig[], composeNetworkName: string): Promise<void> {
    const settings = {
      composeNetworkName,
      fabricCaVersion: global.fabricCaVersion,
      global,
      orgs: orgsTransformed,
      paths: global.paths,
      fabloVersion: config.fabloVersion,
      fabloBuild: getBuildInfo(),
      fabloRestVersion: "0.1.2",
      hyperledgerExplorerVersion: "2.0.0",
      fabricCouchDbVersion: "0.4.18",
      couchDbVersion: "3.1",
      fabricCaPostgresVersion: "14",
    };
    const templatePath = getTemplatePath(this.templatesDir, "fabric-docker/.env");
    const destPath = getDestinationPath(this.outputDir, "fabric-docker/.env");
    await renderTemplate(templatePath, destPath, settings);
  }

  async _copyDockerCompose(config: FabloConfigExtended): Promise<void> {
    const templatePath = getTemplatePath(this.templatesDir, "fabric-docker/docker-compose.yaml");
    const destPath = getDestinationPath(this.outputDir, "fabric-docker/docker-compose.yaml");
    await renderTemplate(templatePath, destPath, config as unknown as Record<string, unknown>);
  }

  async _copyCommandsGeneratedScript(config: FabloConfigExtended): Promise<void> {
    const scripts = [
      "fabric-docker/channel-query-scripts.sh",
      "fabric-docker/chaincode-scripts.sh",
      "fabric-docker/snapshot-scripts.sh",
      "fabric-docker/commands-generated.sh",
    ];

    for (const script of scripts) {
      const templatePath = getTemplatePath(this.templatesDir, script);
      const destPath = getDestinationPath(this.outputDir, script);
      await renderTemplate(templatePath, destPath, config as unknown as Record<string, unknown>);
    }
  }

  async _createPrivateDataCollectionConfigs(chaincodes: ChaincodeConfig[]): Promise<void> {
    for (const { privateData, privateDataConfigFile } of chaincodes) {
      if (privateData && privateData.length && !!privateDataConfigFile) {
        const destPath = getDestinationPath(this.outputDir, `fabric-config/${privateDataConfigFile}`);
        await fs.ensureDir(path.dirname(destPath));
        await fs.writeFile(destPath, JSON.stringify(privateData, undefined, 2), "utf-8");
      }
    }
  }

  async _copyUtilityScripts(capabilities: Capabilities): Promise<void> {
    // Copy fabric-docker.sh
    const fabricDockerShTemplate = getTemplatePath(this.templatesDir, "fabric-docker.sh");
    const fabricDockerShDest = getDestinationPath(this.outputDir, "fabric-docker.sh");
    await renderTemplate(fabricDockerShTemplate, fabricDockerShDest, {});

    // Copy channel_fns script (v2 or v3)
    const channelFnsTemplate = getTemplatePath(
      this.templatesDir,
      `fabric-docker/scripts/cli/channel_fns-${capabilities.isV3 ? "v3" : "v2"}.sh`,
    );
    const channelFnsDest = getDestinationPath(this.outputDir, "fabric-docker/scripts/cli/channel_fns.sh");
    await renderTemplate(channelFnsTemplate, channelFnsDest, {});

    // Copy base-functions script (v2 or v3)
    const baseFunctionsTemplate = getTemplatePath(
      this.templatesDir,
      `fabric-docker/scripts/base-functions-${capabilities.isV3 ? "v3" : "v2"}.sh`,
    );
    const baseFunctionsDest = getDestinationPath(this.outputDir, "fabric-docker/scripts/base-functions.sh");
    await renderTemplate(baseFunctionsTemplate, baseFunctionsDest, {});

    // Copy channel-query-functions.sh
    const channelQueryTemplate = getTemplatePath(this.templatesDir, "fabric-docker/scripts/channel-query-functions.sh");
    const channelQueryDest = getDestinationPath(this.outputDir, "fabric-docker/scripts/channel-query-functions.sh");
    await renderTemplate(channelQueryTemplate, channelQueryDest, {});

    // Copy base-help.sh
    const baseHelpTemplate = getTemplatePath(this.templatesDir, "fabric-docker/scripts/base-help.sh");
    const baseHelpDest = getDestinationPath(this.outputDir, "fabric-docker/scripts/base-help.sh");
    await renderTemplate(baseHelpTemplate, baseHelpDest, {});

    // Copy chaincode-functions script
    const chaincodeFunctionsTemplate = getTemplatePath(
      this.templatesDir,
      `fabric-docker/scripts/chaincode-functions-${capabilities.isV2 ? "v2" : "v2"}.sh`,
    );
    const chaincodeFunctionsDest = getDestinationPath(this.outputDir, "fabric-docker/scripts/chaincode-functions.sh");
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

