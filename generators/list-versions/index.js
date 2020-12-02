/* eslint no-underscore-dangle: 0 */

/*
* License-Identifier: Apache-2.0
*/
const Generator = require('yeoman-generator');

const { getAvailableTags } = require('../list-compatible-updates/repositoryUtils');

module.exports = class extends Generator {
  async printAllVersions() {
    const allVersions = (await getAvailableTags())
      .map((version) => version.name)
      .map((versionName) => versionName.split('.'));
    this.log(allVersions);
  }
};
