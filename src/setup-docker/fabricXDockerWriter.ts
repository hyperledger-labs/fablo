import { FabloConfigExtended } from "../types/FabloConfigExtended";
import { renderTemplate, getTemplatePath, getDestinationPath } from "../utils/templateUtils";
import { shellQuote } from "../utils/shellQuote";
import defaults from "../extend-config/defaults";
import * as fs from "fs-extra";
import * as path from "path";

export const BASE_SIDECAR_PORT = 4001;
export const BASE_QUERY_SERVICE_PORT = 7001;

export interface FabricXOrgConfig {
  name: string;
  domain: string;
  mspName: string;
  slug: string;
  sidecarPort: number;
  queryServicePort: number;
}

export interface FabricXTemplateModel {
  channelName: string;
  channelProfileName: string;
  applicationOrgs: FabricXOrgConfig[];
  defaultPolicy: string;
}

export const getFabricXTemplateModel = (configExtended: FabloConfigExtended): FabricXTemplateModel => {
  const [channel] = configExtended.channels;
  if (!channel || configExtended.channels.length !== 1) {
    throw new Error("Fabric-X generation requires exactly one channel.");
  }
  if (!channel.orgs?.length) {
    throw new Error("Fabric-X generator requires at least one channel with an organization.");
  }

  const applicationOrgs: FabricXOrgConfig[] = channel.orgs.map((org, index) => ({
    name: org.name,
    domain: org.domain,
    mspName: org.mspName,
    slug: org.name.toLowerCase(),
    sidecarPort: BASE_SIDECAR_PORT + index,
    queryServicePort: BASE_QUERY_SERVICE_PORT + index,
  }));

  const defaultPolicy = defaults.namespace.policy(channel.orgs);

  return {
    channelName: channel.name,
    channelProfileName: channel.profileName,
    applicationOrgs,
    defaultPolicy,
  };
};

export class FabricXDockerWriter {
  constructor(private templatesDir: string, private outputDir: string, private log: (msg: string) => void) {}

  public async write(configExtended: FabloConfigExtended): Promise<void> {
    this.log("Generating Fabric-X network files...");

    const fabricX = getFabricXTemplateModel(configExtended);
    const data = {
      ...configExtended,
      fabricX,
      shellQuote,
    };

    await this.renderTemplateFile("fabric-x-docker.sh", data);
    await this.renderTemplateDirectory("fabric-x", data);
    await this.renderPerOrgTemplates(fabricX.applicationOrgs, data);

    this.log("Fabric-X network files successfully generated under fabric-x/");
  }

  private async renderTemplateFile(file: string, data: Record<string, unknown>, destFile?: string): Promise<void> {
    const templatePath = getTemplatePath(this.templatesDir, file);
    const destPath = getDestinationPath(this.outputDir, destFile ?? file);
    await renderTemplate(templatePath, destPath, data);
  }

  private async renderTemplateDirectory(dir: string, data: Record<string, unknown>): Promise<void> {
    const templateDirPath = getTemplatePath(this.templatesDir, dir);

    const entries = await fs.readdir(templateDirPath, { withFileTypes: true });

    for (const entry of entries) {
      const relativePath = path.join(dir, entry.name);

      if (entry.isDirectory()) {
        await this.renderTemplateDirectory(relativePath, data);
      } else if (entry.isFile() && !this.perOrgSources.has(relativePath)) {
        await this.renderTemplateFile(relativePath, data);
      }
    }
  }

  private readonly perOrgTemplates: [string, (slug: string) => string][] = [
    ["fabric-x/config/validator.yaml", (slug) => `fabric-x/config/committer-${slug}-validator.yaml`],
    ["fabric-x/config/committer-coordinator.yaml", (slug) => `fabric-x/config/committer-${slug}-coordinator.yaml`],
    ["fabric-x/config/sidecar.yaml", (slug) => `fabric-x/config/committer-${slug}-sidecar.yaml`],
    ["fabric-x/config/query-service.yaml", (slug) => `fabric-x/config/committer-${slug}-query-service.yaml`],
    ["fabric-x/fxconfig.yaml", (slug) => `fabric-x/fxconfig-${slug}.yaml`],
  ];

  private readonly perOrgSources = new Set(this.perOrgTemplates.map(([src]) => src));

  private async renderPerOrgTemplates(
    applicationOrgs: FabricXOrgConfig[],
    baseData: Record<string, unknown>,
  ): Promise<void> {
    for (const org of applicationOrgs) {
      const orgData = { ...baseData, org };
      for (const [src, getDest] of this.perOrgTemplates) {
        await this.renderTemplateFile(src, orgData, getDest(org.slug));
      }
    }
  }
}
