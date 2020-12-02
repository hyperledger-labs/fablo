/* eslint no-underscore-dangle: 0 */

/*
* License-Identifier: Apache-2.0
*/
const Generator = require('yeoman-generator');

const chalk = require('chalk');
const { version } = require('../config');
const { getAvailableTags } = require('./repositoryUtils');

module.exports = class extends Generator {
  async checkForCompatibleUpdates() {
    const allNewerVersions = await this._getAllNewerVersions(version);
    await this._printCompatibleVersionsOnly(allNewerVersions);
  }

  async _printCompatibleVersionsOnly(allNewerVersions) {
    const compatibleVersions = allNewerVersions.filter((versionName) => versionName.startsWith('0.0.'));
    if (compatibleVersions.length > 0) {
      this.log(chalk.bold('====== !Compatible Fabrica versions found! :) ============='));
      this.log(`${chalk.underline.bold('Compatible')} versions: ${JSON.stringify(compatibleVersions, null, 2)}`);
      this.log('');
      this.log('To update just run command:');
      this.log(`\t${chalk.bold('fabrica use [version]')}`);
      this.log(chalk.bold('==========================================================='));
    }
  }

  async _getAllVersionsSorted() {
    const tagsResponse = await getAvailableTags();
    return tagsResponse.map((result) => ({
      name: result.name,
      last_pushed: result.tag_last_pushed,
    }))
      .sort((a, b) => new Date(b.last_pushed) - new Date(a.last_pushed))
      .map((result) => result.name);
  }

  async _getAllNewerVersions(currentVersion) {
    const allAvailableVersions = await this._getAllVersionsSorted();

    const currentVersionIndex = allAvailableVersions.reverse().indexOf(currentVersion);
    return allAvailableVersions.slice(currentVersionIndex + 1, allAvailableVersions.length)
      .reverse();
  }
};
