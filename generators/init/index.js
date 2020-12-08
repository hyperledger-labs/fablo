/* eslint no-underscore-dangle: 0 */

/*
* License-Identifier: Apache-2.0
*/
const Generator = require('yeoman-generator');
const chalk = require('chalk');
const simpleFabricaConfigJson = require('../../samples/fabricaConfig-1org-1channel-1chaincode');

module.exports = class extends Generator {
  async copySampleConfig() {
    this.fs.writeJSON(
      'fabrica-config.json',
      simpleFabricaConfigJson,
    );

    this.on('end', () => {
      this.log('===========================================================');
      this.log(chalk.bold('Sample config file created! :)'));
      this.log('');
      this.log(`Please note that chaincode directory is '${simpleFabricaConfigJson.chaincodes[0].directory}'.`);
      this.log('If it\'s empty your network won\'t run entirely.');
      this.log('===========================================================');
    });
  }
};
