import * as ejs from "ejs";
import * as fs from "fs-extra";
import * as path from "path";

/**
 * Renders an EJS template file and writes it to the destination
 * @param templatePath Path to the template file
 * @param destinationPath Path where the rendered file should be written
 * @param data Data object to pass to the template
 */
export async function renderTemplate(
  templatePath: string,
  destinationPath: string,
  data: Record<string, unknown> = {},
): Promise<void> {
  const templateContent = await fs.readFile(templatePath, "utf-8");
  const rendered = ejs.render(templateContent, data, {
    filename: templatePath,
  });

  // Ensure destination directory exists
  await fs.ensureDir(path.dirname(destinationPath));
  await fs.writeFile(destinationPath, rendered, "utf-8");
}

/**
 * Copies a file (non-template) to destination
 * @param sourcePath Path to the source file
 * @param destinationPath Path where the file should be copied
 */
export async function copyFile(sourcePath: string, destinationPath: string): Promise<void> {
  await fs.ensureDir(path.dirname(destinationPath));
  await fs.copy(sourcePath, destinationPath);
}

/**
 * Gets the template path relative to the templates directory
 * @param templatesDir Base directory containing templates
 * @param templateFile Relative path to template file
 */
export function getTemplatePath(templatesDir: string, templateFile: string): string {
  return path.join(templatesDir, templateFile);
}

/**
 * Gets the destination path relative to the output directory
 * @param outputDir Base output directory
 * @param destinationFile Relative path to destination file
 */
export function getDestinationPath(outputDir: string, destinationFile: string): string {
  return path.join(outputDir, destinationFile);
}

