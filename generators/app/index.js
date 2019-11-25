/*
 * License-Identifier: Apache-2.0
 */

'use strict';

const Generator = require('yeoman-generator');
module.exports = class extends Generator {

    async initializing() {
        this.log('=== Made with love by SoftwareMill softwaremill.com ===');
    }

    async prompting() {
        const questions = [{
           type: 'list',
           name: 'subgenerator',
           message: 'What you gonna do today ?',
           choices: [
               {name: 'Create (network, organisation, peer)', value: 'create'},
               {name: 'Export (create config.json file)', value: 'export'},
               {name: 'Update (update saved config)', value: 'update'},
               {name: 'Import (import config.json file)', value: 'import'},
               {name: 'Environment (run it as docker-compose or helm)', value: 'environment'}
           ],
            when: () => !this.options.subgenerator
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
