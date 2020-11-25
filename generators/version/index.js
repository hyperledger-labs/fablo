/* eslint no-underscore-dangle: 0 */
/* eslint import/no-unresolved: 0 */
/* eslint import/no-absolute-path: 0 */

/*
* License-Identifier: Apache-2.0
*/
const Generator = require('yeoman-generator');

const config = require('../config');
const { buildInfo } = require('/fabrica/version.json');

module.exports = class extends Generator {
  constructor(args, opts) {
    super(args, opts);
    this.option('verbose', {
      alias: "v"
    });
  }

  async printVersion() {
    if (typeof this.options.verbose !== 'undefined') {
      this.log(JSON.stringify(this._fullInfo(), null, 2));
    } else {
      this.log(JSON.stringify(this._basicInfo(), null, 2));
    }
  }

  _basicInfo() {
    return {
      version: config.version,
      build: buildInfo,
    };
  }

  _fullInfo() {
    return {
      version: config.version,
      build: buildInfo,
      support: {
        hyperledgerFabricVersions: config.supportedFabricVersions,
        fabricaVersions: config.supportedFabricaVersions,
      },
    };
  }
};
