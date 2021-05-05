import Generator from "yeoman-generator";
import chalk from "chalk";
import * as config from "../config";
import * as repositoryUtils from "../repositoryUtils";

export default class ListCompatibleUpdatesGenerator extends Generator {
  async checkForCompatibleUpdates(): Promise<void> {
    const allNewerVersions = (await repositoryUtils.getAvailableTags()).filter(
      (name) => config.isFabricaVersionSupported(name) && name > config.fabricaVersion,
    );

    this._printVersions(allNewerVersions);
  }

  _printVersions(versionsToPrint: string[]): void {
    if (versionsToPrint.length > 0) {
      this.log(chalk.bold("====== !Compatible Fabrica versions found! :) ============="));
      this.log(`${chalk.underline.bold("Compatible")} versions:`);
      versionsToPrint.forEach((version) => this.log(`- ${version}`));
      this.log("");
      this.log("To update just run command:");
      this.log(`\t${chalk.bold("fabrica use [version]")}`);
      this.log(chalk.bold("==========================================================="));
    }
  }
}
