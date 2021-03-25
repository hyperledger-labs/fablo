/* eslint no-underscore-dangle: 0 */

/*
* License-Identifier: Apache-2.0
*/
const Generator = require('yeoman-generator');

const chalk = require('chalk');
const config = require('../config');
const repositoryUtils = require('../repositoryUtils');

module.exports = class extends Generator {
  async checkForCompatibleUpdates() {
    const allNewerVersions = (await repositoryUtils.getAvailableTags())
      .filter((name) => config.isFabricaVersionSupported(name) && name > config.fabricaVersion);

    this._printVersions(allNewerVersions);
  }

  _printVersions(versionsToPrint) {
    if (versionsToPrint.length > 0) {
      this.log(chalk.bold('====== !Compatible Fabrica versions found! :) ============='));
      this.log(`${chalk.underline.bold('Compatible')} versions:`);
      versionsToPrint.forEach((version) => this.log(`- ${version}`));
      this.log('');
      this.log('To update just run command:');
      this.log(`\t${chalk.bold('fabrica use [version]')}`);
      this.log(chalk.bold('==========================================================='));
    }
  }
};
