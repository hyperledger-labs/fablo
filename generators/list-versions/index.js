/* eslint no-underscore-dangle: 0 */

/*
* License-Identifier: Apache-2.0
*/
const Generator = require('yeoman-generator');

const config = require('../config');
const repositoryUtils = require('../repositoryUtils');

module.exports = class extends Generator {
  async printAllVersions() {
    const allVersions = await repositoryUtils.getAvailableTags();

    const versionsSortedAndMarked = repositoryUtils
      .sortVersions(allVersions)
      .map(this._markAsCurrent)
      .map(this._markAsCompatible);

    this.log(JSON.stringify(versionsSortedAndMarked, null, 2));
  }

  _markAsCurrent(versionToCheck) {
    if (versionToCheck === config.version) {
      return `${versionToCheck} <== current`;
    }
    return versionToCheck;
  }

  _markAsCompatible(versionToCheck) {
    if (config.isFabricaVersionSupported(versionToCheck)) {
      return `${versionToCheck} (compatible)`;
    }
    return versionToCheck;
  }
};
