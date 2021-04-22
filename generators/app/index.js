const Generator = require('yeoman-generator');
const config = require('../config');

module.exports = class extends Generator {
  async initializing() {
    this.log(config.splashScreen());
  }

  async displayInfo() {
    const url = 'https://github.com/softwaremill/fabrica';
    this.log('This is main entry point for Yeoman app used in Fabrica.');
    this.log('Visit the project page to get more information.');
    this.log(`---\n${url}\n---`);
  }
};
