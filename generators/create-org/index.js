
const Generator = require('yeoman-generator');
const utils = require('../utils');

const defaultOrgName = (orgKey) => `My ${orgKey === utils.rootKey ? 'Root ' : ''}Organization`;
const defaultOrgDomain = (orgKey) => `${orgKey}.example.com`;
const configKey = 'organization';

module.exports = class extends Generator {
  async prompting() {
    const { orgKey } = this.options;
    const { name, domain } = await utils.loadConfig(this.config, orgKey, configKey);

    const questions = [{
      type: 'input',
      name: 'name',
      message: `[${orgKey}] Organization:\n${utils.tab}name`,
      default: name || defaultOrgName,
    }, {
      type: 'input',
      name: 'domain',
      message: `${utils.tab}domain`,
      default: domain || defaultOrgDomain(orgKey),
    }];

    const answers = { key: orgKey, ...await this.prompt(questions) };
    await utils.saveConfig(this.config, orgKey, configKey, answers);
  }
};
