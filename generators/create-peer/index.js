'use strict';

const Generator = require('yeoman-generator');
const utils = require('../utils');

const defaultPeerPrefix = 'peer';
const defaultNumberOfInstances = 3;
const configKey = 'peer';

module.exports = class extends Generator {

  async prompting() {
    const orgKey = this.options.orgKey;
    const {prefix, instances} = await utils.loadConfig(this.config, orgKey, configKey);

    const questions = [{
      type: 'input',
      name: 'prefix',
      message: `[${orgKey}] Peer:\n${utils.tab}hostname prefix`,
      default: prefix || defaultPeerPrefix,
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
