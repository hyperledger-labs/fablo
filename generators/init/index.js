/* eslint no-underscore-dangle: 0 */

/*
* License-Identifier: Apache-2.0
*/
const Generator = require('yeoman-generator');
const simpleFabricaConfigJson = require('../../samples/fabricaConfig-1org-1channel-1chaincode');

module.exports = class extends Generator {
  async copySimpleFile() {
    this.fs.writeJSON(
      'fabrica-config.json',
      simpleFabricaConfigJson,
    );
  }
};
