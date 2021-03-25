/* eslint no-underscore-dangle: 0 */

/*
* License-Identifier: Apache-2.0
*/
const Generator = require('yeoman-generator');
const chalk = require('chalk');

module.exports = class extends Generator {
  async copySampleConfig() {
    this.fs.copy(this.templatePath(), this.destinationPath());

    this.on('end', () => {
      this.log('===========================================================');
      this.log(chalk.bold('Sample config file created! :)'));
      this.log('You can start your network with \'fabrica up\' command');
      this.log('===========================================================');
    });
  }
};
