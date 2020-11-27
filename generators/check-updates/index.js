/* eslint no-underscore-dangle: 0 */

/*
* License-Identifier: Apache-2.0
*/
const Generator = require('yeoman-generator');

const got = require('got');
const chalk = require('chalk');
const { version } = require('../config');

const dockerRepositoryName = 'softwaremill/fabrica';

module.exports = class extends Generator {
  constructor(args, opts) {
    super(args, opts);
    this.option('compatible', {
      alias: 'c',
      description: 'Print only if compatible versions where found',
    });
  }

  async checkUpdates() {
    const allAvailableVersions = await this._getAllVersionsSorted();
    const allNewerVersions = this._getAllNewerVersions(version, allAvailableVersions);

    if (typeof this.options.compatible === 'undefined') {
      await this._printAllVersions(allNewerVersions);
    } else {
      await this._printCompatibleVersionsOnly(allNewerVersions);
    }
  }

  async _printAllVersions(allNewerVersions) {
    if (allNewerVersions.length > 0) {
      const msg = chalk.bold('There are new fabrica versions available! :)');
      this.log(msg);
      this.log(`${chalk.underline.bold('all')} newer versions: ${JSON.stringify(allNewerVersions, null, 2)}`);
      this.log('');
      this.log('To update just run command:');
      this.log(`\t${chalk.bold('fabrica updateTo [version]')}`);
    } else {
      this.log(chalk.bold(`No updates available. ${version} seems to be the latest one`));
    }
  }

  async _printCompatibleVersionsOnly(allNewerVersions) {
    const compatibleVersions = allNewerVersions.filter((versionName) => versionName.startsWith('0.0.'));
    if (compatibleVersions.length > 0) {
      this.log(chalk.bold('Compatible Fabrica versions found! :)'));
      this.log(`${chalk.underline.bold('Compatible')} versions: ${JSON.stringify(compatibleVersions, null, 2)}`);
      this.log('');
      this.log('To update just run command:');
      this.log(`\t${chalk.bold('fabrica updateTo [version]')}`);
    }
  }

  async _getAllVersionsSorted() {
    const url = `https://registry.hub.docker.com/v2/repositories/${dockerRepositoryName}/tags`;
    const params = {
      searchParams: {
        tag_status: 'active',
        page_size: 1024,
      },
    };
    const tagsResponse = await got(url, params).json();
    return tagsResponse.results.map((result) => ({
      name: result.name,
      last_pushed: result.tag_last_pushed,
    }))
      .filter((result) => result.name !== 'latest')
      .sort((a, b) => new Date(b.last_pushed) - new Date(a.last_pushed))
      .map((result) => result.name);
  }

  _getAllNewerVersions(currentVersion, allVersions) {
    const currentVersionIndex = allVersions.reverse().indexOf(currentVersion);
    return allVersions.slice(currentVersionIndex + 1, allVersions.length).reverse();
  }
};
