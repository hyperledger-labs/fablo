
const Generator = require('yeoman-generator');
const utils = require('../utils');

const defaultCAPrefix = 'ca';
const configKey = 'ca';

module.exports = class extends Generator {
  async prompting() {
    const { orgKey } = this.options;
    const { prefix } = await utils.loadConfig(this.config, orgKey, configKey);

    const questions = [{
      type: 'input',
      name: 'prefix',
      message: `[${orgKey}] Certificate Authority (CA):\n${utils.tab}hostname prefix`,
      default: prefix || defaultCAPrefix,
    }, {
      type: 'confirm',
      name: 'generate',
      message: `${utils.tab}Generate CA for this organization ?`,
      default: true,
    },
    ];

    const answers = await this.prompt(questions);
    await utils.saveConfig(this.config, orgKey, configKey, answers);
  }
};
