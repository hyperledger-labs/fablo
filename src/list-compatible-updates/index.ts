import * as Generator from "yeoman-generator";
import * as chalk from "chalk";
import * as config from "../config";
import * as repositoryUtils from "../repositoryUtils";

export default class ListCompatibleUpdatesGenerator extends Generator {
  async checkForCompatibleUpdates(): Promise<void> {
    const allNewerVersions = (await repositoryUtils.getAvailableTags()).filter(
      (name) => config.isFabloVersionSupported(name) && name > config.fabloVersion,
    );

    this._printVersions(allNewerVersions);
  }

  _printVersions(versionsToPrint: string[]): void {
    if (versionsToPrint.length > 0) {
      console.log(chalk.bold("====== !Compatible Fablo versions found! :) ============="));
      console.log(`${chalk.underline.bold("Compatible")} versions:`);
      versionsToPrint.forEach((version) => console.log(`- ${version}`));
      console.log("");
      console.log("To update just run command:");
      console.log(`\t${chalk.bold("fablo use [version]")}`);
      console.log(chalk.bold("==========================================================="));
    }
  }
}
