/*
 * License-Identifier: Apache-2.0
 */


const Generator = require('yeoman-generator');

module.exports = class extends Generator {
  desc() {
    this.log('Exports produced config to config.json, which can be shared between organizations or developers');
  }

  splash() {
    this.log('Nothing there yet... Sorry !');
  }
};
