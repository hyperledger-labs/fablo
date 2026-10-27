import { FabloConfigExtended, OrgConfig } from "../types/FabloConfigExtended";
import { renderTemplate, getTemplatePath, getDestinationPath } from "../utils/templateUtils";
import { shellQuote } from "../utils/shellQuote";
import * as fs from "fs-extra";
import * as path from "path";
import { buildFabricXOrdererTopology, FabricXOrdererTopology } from "./fabricXOrdererTopology";

export interface FabricXTemplateModel {
  channelName: string;
  channelProfileName: string;
  applicationOrg: OrgConfig;
  applicationOrgSlug: string;
  orderer:FabricXOrdererTopology;
}

export const getFabricXTemplateModel = (configExtended: FabloConfigExtended): FabricXTemplateModel => {
  const [channel] = configExtended.channels;
  if (!channel) {
    throw new Error("Fabric-X generation requires exactly one channel.");
  }
  if (!channel.instantiatingOrg) {
    throw new Error("Fabric-X generator requires at least one channel with an organization.");
  }
  return {
    channelName: channel.name,
    channelProfileName: channel.profileName,
    applicationOrg: channel.instantiatingOrg,
    applicationOrgSlug: channel.instantiatingOrg.name.toLowerCase(),
    orderer: buildFabricXOrdererTopology(configExtended.fabricX?.orderer.parties ?? []),
};
};
export class FabricXDockerWriter {
  constructor(private templatesDir: string, private outputDir: string, private log: (msg: string) => void) {}

  public async write(configExtended: FabloConfigExtended): Promise<void> {
    this.log("Generating Fabric-X network files...");

    const fabricX = getFabricXTemplateModel(configExtended);
    const data = {
      ...(configExtended as unknown as Record<string, unknown>),
      fabricX,
      shellQuote,
    };

    await this.renderTemplateFile("fabric-x-docker.sh", data);
    await this.renderTemplateDirectory("fabric-x", data);
    await this.renderOrdererNodeConfigs(fabricX.orderer, data);

    this.log("Fabric-X network files successfully generated under fabric-x/");
  }

private async renderOrdererNodeConfigs(orderer: FabricXOrdererTopology, data: Record<string, unknown>): Promise<void> {
  for (const party of orderer.parties) {
    for (const node of party.nodes) {
      const templatePath = getTemplatePath(this.templatesDir, path.join("fabric-x-orderer", `orderer-${node.role}.yaml`));
      const destPath = getDestinationPath(this.outputDir, path.join("fabric-x", node.configFile));
      await renderTemplate(templatePath, destPath, { ...data, party, node });
    }
  }
}
  private async renderTemplateFile(file: string, data: Record<string, unknown>): Promise<void> {
    const templatePath = getTemplatePath(this.templatesDir, file);
    const destPath = getDestinationPath(this.outputDir, file);
    await renderTemplate(templatePath, destPath, data);
  }

  private async renderTemplateDirectory(dir: string, data: Record<string, unknown>): Promise<void> {
    const templateDirPath = getTemplatePath(this.templatesDir, dir);

    const entries = await fs.readdir(templateDirPath, { withFileTypes: true });

    for (const entry of entries) {
      const relativePath = path.join(dir, entry.name);

      if (entry.isDirectory()) {
        await this.renderTemplateDirectory(relativePath, data);
      } else if (entry.isFile()) {
        await this.renderTemplateFile(relativePath, data);
      }
    }
  }
}