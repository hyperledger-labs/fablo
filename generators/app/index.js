
const Generator = require('yeoman-generator');
const utils = require('../utils');

module.exports = class extends Generator {
  async initializing() {
    this.log(utils.splashScreen());
  }

  async prompting() {
    const questions = [{
      type: 'list',
      name: 'subgenerator',
      message: 'What you gonna do today ?',
      choices: [
        { name: 'Create new HLF network', value: 'create' },
        { name: 'Export (create config.json file)', value: 'export' },
        { name: 'Update (update saved config)', value: 'update' },
        { name: 'Import (import config.json file)', value: 'import' },
        { name: 'Setup environment (translate config.json to docker-compose or helm)', value: 'setup' },
      ],
      when: () => !this.options.subgenerator,
    }];
    const answers = await this.prompt(questions);
    Object.assign(this.options, answers);
  }

  async configuring() {
    const { subgenerator } = this.options;
    this.log(`This generator can also be run with: yo fabric-network:${subgenerator}`);
    this.composeWith(require.resolve(`../${subgenerator}`), this.options);
  }
};
