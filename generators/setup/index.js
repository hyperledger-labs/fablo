/*
 * License-Identifier: Apache-2.0
 */

const Generator = require('yeoman-generator');

module.exports = class extends Generator {
  async prompting() {
    const questions = [{
      type: 'list',
      name: 'setupType',
      message: 'Select type of environment to create',
      choices: [
        { name: 'docker-compose', value: 'setup-docker' },
        { name: 'Helm', value: 'setup-helm' },
      ],
    }];
    const answers = await this.prompt(questions);
    Object.assign(this.options, answers);
  }

  async configuring() {
    const { setup } = this.options;
    this.log(`This generator can also be run with: yo fabrica:${setup.setupType}`);
    this.composeWith(require.resolve(`../${setup.setupType}`), this.options);
  }
};
