/*
 * License-Identifier: Apache-2.0
 */

'use strict';

const Generator = require('yeoman-generator');
module.exports = class extends Generator {

    async writing() {
        const rootOrg = await this.config.get('root');
        const orgs = await this.config.get('orgs');
        this.fs.copyTpl(
            this.templatePath('network/docker-compose-base.yml'),
            this.destinationPath('network-compose/docker-compose.yml'),
            {
                root: {
                    name: rootOrg.organization.name,
                    domain: rootOrg.organization.domain,
                    ca: {
                        name: rootOrg.ca.prefix
                    },
                    orderer: {
                        name: rootOrg.orderer.prefix,
                    }
                },
                orgs: orgs
            }
        );
        this.fs.copyTpl(
            this.templatePath('network/.env'),
            this.destinationPath('network-compose/.env'),
            {
                fabricVersion: "1.4.2",
                orgs: orgs
            }
        );
    }

};
