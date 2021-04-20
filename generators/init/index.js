/* eslint no-underscore-dangle: 0 */

/*
* License-Identifier: Apache-2.0
*/
const Generator = require('yeoman-generator');
const chalk = require('chalk');

module.exports = class extends Generator {
  async copySampleConfig() {
    if (this._args.length && this._args[0] === 'node') {
      this.fs.copy(this.templatePath(), this.destinationPath());
    } else {
      const json = this.fs.readJSON(this.templatePath('fabrica-config.json'));
      this.fs.write(
        this.destinationPath('fabrica-config.json'),
        JSON.stringify({ ...json, chaincodes: [] }, undefined, 2),
      );
    }

    this.on('end', () => {
      this.log('===========================================================');
      this.log(chalk.bold('Sample config file created! :)'));
      this.log('You can start your network with \'fabrica up\' command');
      this.log('===========================================================');
    });
  }
};
