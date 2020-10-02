/* eslint no-underscore-dangle: 0 */
const Generator = require('yeoman-generator');
const config = require('../config');

module.exports = class extends Generator {
  async initializing() {
    this.log(config.splashScreen());
  }

  async displayManual() {
    this.log(this.arguments);
    this.log(this.options);

    const questions = [{
      type: 'list',
      name: 'manualOption',
      message: 'Welcome to the manual! Select option for more details :',
      choices: [
        {
          name: "yo fabrikka:version \t\t\t\t: prints Fabrikka's version",
          value: 'version',
        },
        {
          name: 'yo fabrikka:setup-docker configFile.json \t: create docker-compose network based on config',
          value: 'setupCompose',
        },
        {
          name: 'exit',
          value: 'exit',
        },
      ],
      when: () => !this.options.manualOption,
    }];
    const answers = await this.prompt(questions);
    this.options.answers = answers;
    this._printHelp();
  }

  _printHelp() {
    const { manualOption } = this.options.answers;
    switch (manualOption) {
      case 'version':
        this._versionHelp();
        break;
      case 'setupCompose':
        this._setupComposeHelp();
        break;
      default:
    }
  }

  _versionHelp() {
    this.log('yo fabrikka:version : robie ważne rzeczy. serio. '); // FIXME
  }

  _setupComposeHelp() {
    this.log('yo fabrikka:setup-docker : robie ważne rzeczy. serio. '); // FIXME
  }
};
