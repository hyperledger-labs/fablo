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

    async _printAllVersions(allNewerVersions) {
        if (allNewerVersions.length > 0) {
            this.log(chalk.bold('====== !There are new fabrica versions available! :) ======'));
            this.log(`${chalk.underline.bold('all')} newer versions: ${JSON.stringify(allNewerVersions, null, 2)}`);
            this.log('');
            this.log('To update just run command:');
            this.log(`\t${chalk.bold('fabrica use [version]')}`);
            this.log(chalk.bold('==========================================================='));
        } else {
            this.log(chalk.bold(`No updates available. ${version} seems to be the latest one`));
        }
    }

}
