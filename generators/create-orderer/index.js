'use strict';

const Generator = require('yeoman-generator');

const defaultCAPrefix = 'ord';
const defaultNumberOfInstances = 1;

module.exports = class extends Generator {

  async prompting() {
    const questions = [{
      type: 'input',
      name: 'prefix',
      message: 'Orderer hostname prefix',
      default: defaultCAPrefix,
    }, {
      type: 'number',
      name: 'instances',
      message: 'Number of instances',
      default: defaultNumberOfInstances,
    }];
    const answers = await this.prompt(questions);
    this.config.set('orderer', answers);
  }

};
