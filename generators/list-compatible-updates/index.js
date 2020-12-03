/* eslint no-underscore-dangle: 0 */

/*
* License-Identifier: Apache-2.0
*/
const Generator = require('yeoman-generator');

const chalk = require('chalk');
const { version } = require('../config');
const repositoryUtils = require('../repositoryUtils');

module.exports = class extends Generator {
  async checkForCompatibleUpdates() {
    const allNewerVersions = (await this._getAllVersionsSorted())
      .filter((name) => name.startsWith('0.0.') && name > version);

    this._printVersions(allNewerVersions);
  }

  _printVersions(versionsToPrint) {
    if (versionsToPrint.length > 0) {
      this.log(chalk.bold('====== !Compatible Fabrica versions found! :) ============='));
      this.log(`${chalk.underline.bold('Compatible')} versions: ${JSON.stringify(versionsToPrint, null, 2)}`);
      this.log('');
      this.log('To update just run command:');
      this.log(`\t${chalk.bold('fabrica use [version]')}`);
      this.log(chalk.bold('==========================================================='));
    }
  }

  async _getAllVersionsSorted() {
    const tagsResponse = await repositoryUtils.getAvailableTags();
    return repositoryUtils.sortVersions(tagsResponse);
  }
};
