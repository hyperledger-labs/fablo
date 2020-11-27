/* eslint no-underscore-dangle: 0 */

/*
* License-Identifier: Apache-2.0
*/
const Generator = require('yeoman-generator');

const buildUtil = require('./buildUtil');
const config = require('../config');

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
      build: buildUtil.getBuildInfo(),
    };
  }

  _fullInfo() {
    return {
      version: config.version,
      build: buildUtil.getBuildInfo(),
      supported: {
        hyperledgerFabricVersions: config.supportedFabricVersions,
        fabricaVersions: `${config.supportedVersionPrefix}x`,
      },
    };
  }
};
