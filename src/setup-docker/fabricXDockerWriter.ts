import { FabloConfigExtended } from "../types/FabloConfigExtended";
import { renderTemplate, getTemplatePath, getDestinationPath } from "../utils/templateUtils";
import * as fs from "fs-extra";
import * as path from "path";

export class FabricXDockerWriter {
  constructor(private templatesDir: string, private outputDir: string, private log: (msg: string) => void) {}

  public async write(configExtended: FabloConfigExtended): Promise<void> {
    this.log("Generating Fabric-X network files...");

    const data = configExtended as unknown as Record<string, unknown>;

    await this.renderTemplateFile("fabric-x-docker.sh", data);
    await this.renderTemplateDirectory("fabric-x", data);

    this.log("Fabric-X network files successfully generated under fabric-x/");
  }

  private async renderTemplateFile(file: string, data: Record<string, unknown>): Promise<void> {
    const templatePath = getTemplatePath(this.templatesDir, file);
    const destPath = getDestinationPath(this.outputDir, file);
    await renderTemplate(templatePath, destPath, data);
  }

  private async renderTemplateDirectory(dir: string, data: Record<string, unknown>): Promise<void> {
    const templateDirPath = getTemplatePath(this.templatesDir, dir);
    
    if (!(await fs.pathExists(templateDirPath))) {
      return;
    }
    
    const files = await fs.readdir(templateDirPath);
    for (const file of files) {
      const fullPath = path.join(templateDirPath, file);
      const stat = await fs.stat(fullPath);
      const relativePath = path.join(dir, file);
      
      if (stat.isDirectory()) {
        await this.renderTemplateDirectory(relativePath, data);
      } else {
        await this.renderTemplateFile(relativePath, data);
      }
    }
  }
}
