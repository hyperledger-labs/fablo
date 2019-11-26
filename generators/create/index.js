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
               {name: 'Network', value: 'create-network'},
               {name: 'Organisation', value: 'create-organisation'},
               {name: 'Peer', value: 'create-peer'}
           ]
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
