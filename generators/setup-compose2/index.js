/*
 * License-Identifier: Apache-2.0
 */


const Generator = require('yeoman-generator');

const utils = require('../utils');

module.exports = class extends Generator {

    constructor(args, opts) {
        super(args, opts);
        this.argument("fabrikkaConfig", {
            type: String,
            required: true,
            description: "Name of fabrikka config file in current dir"
        });

        const configFilePath = this.getConfigsFullPath(this.options.fabrikkaConfig);
        const fileExists = this.fs.exists(configFilePath);

        if (!fileExists) {
            this.emit('error', new Error(`No file under path: ${configFilePath}`));
        } else {
            this.options.fabrikkaConfigPath = configFilePath;
        }
    }

    async writing() {
        const networkConfig = this.fs.readJSON(this.options.fabrikkaConfigPath);
        const prettyResult = JSON.stringify(networkConfig, undefined, 2);

        this.log(prettyResult);

        this.log("Fabric version is: "+ networkConfig.networkSettings.fabricVersion);
    }

    getConfigsFullPath(configFile) {
        const currentPath = this.env.cwd;
        return currentPath + "/" + configFile;
    }

};

// https://yeoman.io/authoring/file-system.html
// fabrikkaConfig-0.1.json


// parsedOpts[config.name] = value;
// });
//
// // Make the parsed options available to the instance
// Object.assign(this.options, parsedOpts);
