'use strict';

const Generator = require('yeoman-generator');
const utils = require('../utils');

const defaultOrgName = (namespace) => `My ${namespace === 'root' ? 'Root ' : ''}Organization`;
const defaultOrgDomain = (namespace) => `${namespace}.example.com`;

module.exports = class extends Generator {

  async prompting() {
    const namespace = utils.getNamespace(this.options);

    const questions = [{
      type: 'input',
      name: 'name',
      message: `[${namespace}] Organization name`,
      default: defaultOrgName,
    }, {
      type: 'input',
      name: 'domain',
      message: `[${namespace}] Organization domain`,
      default: defaultOrgDomain(namespace),
    }];

    const answers = await this.prompt(questions);
    await utils.updateNamespace(this.config, namespace, 'organization', answers);
  }

};
