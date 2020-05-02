const Generator = require('yeoman-generator');
const splashAndVersions = require('../splashAndVersions');

module.exports = class extends Generator {
    async initializing() {
        this.log(splashAndVersions.splashScreen());
    }

    constructor(args, opts) {
        super(args, opts);
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
                    value: 'version'
                },
                {
                    name: "yo fabrikka:setup-compose configFile.json \t: create docker-compose network based on config",
                    value: 'setupCompose'
                },
                {
                    name: "exit",
                    value: 'exit'
                },
            ],
            when: () => !this.options.manualOption,
        }];
        const answers = await this.prompt(questions);
        this.options.answers = answers;
        this._printHelp();
    }

    _printHelp() {
        const {manualOption} = this.options.answers;
        switch (manualOption) {
            case 'version':
                this._versionHelp();
            case 'setupCompose':
                this._setupComposeHelp();
        }
    }

    _versionHelp() {
        this.log("yo fabrikka:version : robie ważne rzeczy. serio. ");
    }

    _setupComposeHelp() {
        this.log("yo fabrikka:setup-compose : robie ważne rzeczy. serio. ");
    }
};
