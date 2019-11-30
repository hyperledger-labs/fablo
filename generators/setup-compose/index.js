/*
 * License-Identifier: Apache-2.0
 */

'use strict';

const Generator = require('yeoman-generator');
module.exports = class extends Generator {

    async writing() {
        const rootGenerator = await this.config.get('root');
        this.fs.copyTpl(
            this.templatePath('network/docker-compose.yaml'),
            this.destinationPath('network-compose/docker-compose.yaml'),
            {
                "rootDomain": rootGenerator.organization.domain,
                "rootName": rootGenerator.organization.name
            }
        );
        this.fs.copyTpl(
            this.templatePath('network/.env'),
            this.destinationPath('network-compose/.env'),
            {
                "fabricVersion": "1.4.2"
            }
        );
    }

};
