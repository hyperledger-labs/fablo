
const Generator = require('yeoman-generator');
const utils = require('../utils');

module.exports = class extends Generator {
  async prompting() {
    const ogranizationInfo = (o) => {
      const { key, name, domain } = (o || {}).organization || {};
      return `\n${utils.tab}${name} (${key}, ${domain})`;
    };

    const all = await this.config.getAll();
    const root = all[utils.rootKey] || {};
    const other = all[utils.otherOrgsKey] || [];
    const infos = [root].concat(other).map(ogranizationInfo);

    if (infos.length) {
      this.log(`We found the current config for organizations:${infos.join('')}`);

      const questions = [{
        type: 'list',
        message: 'Do you want to delete the current config?',
        name: 'deleteConfig',
        choices: [
          { name: 'Yes', value: 'delete' },
          { name: 'No', value: 'abort' },
        ],
      }];

      const answers = await this.prompt(questions);

      if (answers.deleteConfig === 'delete') {
        await Promise.all(Object.keys(all).map((key) => this.config.delete(key)));
      } else {
        Object.assign(this.options, { oldConfigExists: true });
      }
    }
  }

  async configuring() {
    if (this.options.oldConfigExists) {
      this.options.handleDeleteConfig.onFailure();
    } else {
      this.options.handleDeleteConfig.onSuccess();
    }
  }
};
