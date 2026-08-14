import { FabloConfigExtended } from "../types/FabloConfigExtended";
import { renderTemplate, getTemplatePath, getDestinationPath } from "../utils/templateUtils";

export class FabricXDockerWriter {
  constructor(private templatesDir: string, private outputDir: string, private log: (msg: string) => void) {}

  public async write(configExtended: FabloConfigExtended): Promise<void> {
    this.log("Generating Fabric-X network files...");

    const staticFiles = ["docker-compose.yaml", "crypto-config.yaml", "configtx.yaml", "shared_config.yaml"];

    for (const file of staticFiles) {
      const templatePath = getTemplatePath(this.templatesDir, `fabric-x/${file}`);
      const destPath = getDestinationPath(this.outputDir, `fabric-x/${file}`);
      await renderTemplate(templatePath, destPath, configExtended as unknown as Record<string, unknown>);
    }

    const staticConfigs = [
      "party1-router.yaml",
      "party1-batcher.yaml",
      "party1-consenter.yaml",
      "party1-assembler.yaml",
      "committer-coordinator.yaml",
      "committer-query-service.yaml",
      "committer-sidecar-dev.yaml",
      "committer-validator.yaml",
      "committer-verifier.yaml",
    ];

    for (const config of staticConfigs) {
      const templatePath = getTemplatePath(this.templatesDir, `fabric-x/config/${config}`);
      const destPath = getDestinationPath(this.outputDir, `fabric-x/config/${config}`);
      await renderTemplate(templatePath, destPath, {});
    }

    this.log("Fabric-X network files successfully generated under fabric-x/");
  }
}
