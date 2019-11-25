/*
 * License-Identifier: Apache-2.0
 */

'use strict';

const Generator = require('yeoman-generator');
module.exports = class extends Generator {

    async prompting() {
        const questions = [{
           type: 'list',
           name: 'subgenerator',
           message: 'Select asset to create',
           choices: [
               {name: 'Network', value: 'network'},
               {name: 'Organisation', value: 'organisation'},
               {name: 'Peer', value: 'peer'}
           ]
        }];
        const answers = await this.prompt(questions);
        Object.assign(this.options, answers);
    }

    async configuring() {
        this.log(`All for now. Sorry !`);
    }

};
