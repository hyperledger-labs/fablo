/*
 * License-Identifier: Apache-2.0
 */

'use strict';

const Generator = require('yeoman-generator');
module.exports = class extends Generator {

  async prompting() {
    const questions = [{
      type: 'list',
      name: 'env-type',
      message: 'Select type of environment to create',
      choices: [
        {name: 'docker-compose', value: 'docker-compose'},
        {name: 'Helm', value: 'helm'}
      ]
    }];
    const answers = await this.prompt(questions);
    Object.assign(this.options, answers);
  }

    async writing() {
      const root = await this.config.get(utils.rootKey)
        this.fs.copyTpl(
            this.templatePath('docker-compose/fabric-compose.yaml'),
            this.destinationPath('docker-out/fabric-compose.yaml'),
            { organisation: root.organization.name } // user answer `title` used
        );
    }
};
