import * as Generator from "yeoman-generator";
import * as config from "../config";
import * as repositoryUtils from "../repositoryUtils";

export default class ListVersionsGenerator extends Generator {
  async printAllVersions(): Promise<void> {
    const allVersions = await repositoryUtils.getAvailableTags();
    const versionsSortedAndMarked = allVersions
      .map((v) => (v === config.fabloVersion ? `${v} <== current` : v))
      .map((v) => (config.isFabloVersionSupported(v) && !v.includes("current") ? `${v} (compatible)` : v));

    versionsSortedAndMarked.forEach((version) => this.log(`- ${version}`));
  }
}
