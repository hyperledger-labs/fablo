'use strict';

const Generator = require('yeoman-generator');

const defaultOrgName = 'My Organization';
const defaultOrgDomain = 'my-org.example.com';

module.exports = class extends Generator {

  async prompting() {
    const questions = [{
      type: 'input',
      name: 'name',
      message: 'Organization name',
      default: defaultOrgName,
    }, {
      type: 'input',
      name: 'domain',
      message: 'Organization domain',
      default: defaultOrgDomain,
    }];
    const answers = await this.prompt(questions);
    this.config.set('organization', answers);
  }

};
