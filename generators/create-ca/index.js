'use strict';

const Generator = require('yeoman-generator');
const utils = require('../utils');

const defaultCAPrefix = 'ca';
const defaultNumberOfInstances = 1;

module.exports = class extends Generator {

  async prompting() {
    const namespace = utils.getNamespace(this.options);

    const questions = [{
      type: 'input',
      name: 'prefix',
      message: `[${namespace}] Certificate Authority (CA) hostname prefix`,
      default: defaultCAPrefix,
    }, {
      type: 'number',
      name: 'instances',
      message: `[${namespace}] Number of instances`,
      default: defaultNumberOfInstances,
    }];
    const answers = await this.prompt(questions);
    await utils.updateNamespace(this.config, namespace, 'ca', answers);
  }

};
