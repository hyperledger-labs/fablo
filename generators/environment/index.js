/*
 * License-Identifier: Apache-2.0
 */

'use strict';

const Generator = require('yeoman-generator');
module.exports = class extends Generator {

    async prompting() {
        const questions = [{
            type: 'list',
            name: 'env-type',
            message: 'Select type of environment to create',
            choices: [
                {name: 'docker-compose', value: 'docker-compose'},
                {name: 'Helm', value: 'helm'}
                ]
        }];
        const answers = await this.prompt(questions);
        Object.assign(this.options, answers);
    }

    async configuring() {
        this.log(`All for now. Sorry !`);
    }

};
