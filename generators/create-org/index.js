'use strict';

const Generator = require('yeoman-generator');
const utils = require('../utils');

const defaultOrgName = (orgNamespace) => `My ${orgNamespace === 'root' ? 'Root ' : ''}Organization`;
const defaultOrgDomain = (orgNamespace) => `${orgNamespace}.example.com`;

module.exports = class extends Generator {

  async prompting() {
    const orgNamespace = this.options.orgNamespace;

    const questions = [{
      type: 'input',
      name: 'name',
      message: `[${orgNamespace}] Organization:\n${utils.tab}name`,
      default: defaultOrgName,
    }, {
      type: 'input',
      name: 'domain',
      message: `${utils.tab}domain`,
      default: defaultOrgDomain(orgNamespace),
    }];

    const answers = await this.prompt(questions);
    await utils.updateNamespace(this.config, orgNamespace, 'organization', answers);
  }

};
