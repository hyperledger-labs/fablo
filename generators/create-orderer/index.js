
const Generator = require('yeoman-generator');
const utils = require('../utils');

const defaultOrdererPrefix = 'orderer';
const defaultNumberOfInstances = 1;
const configKey = 'orderer';

module.exports = class extends Generator {
  async prompting() {
    const { orgKey } = this.options;
    const { prefix, instances } = await utils.loadConfig(this.config, orgKey, configKey);

    const questions = [{
      type: 'input',
      name: 'prefix',
      message: `[${orgKey}] Orderer:\n${utils.tab}hostname prefix`,
      default: prefix || defaultOrdererPrefix,
    }, {
      type: 'number',
      name: 'instances',
      message: `${utils.tab}number of instances`,
      default: instances || defaultNumberOfInstances,
    }];

    const answers = await this.prompt(questions);
    await utils.saveConfig(this.config, orgKey, configKey, answers);
  }
};
