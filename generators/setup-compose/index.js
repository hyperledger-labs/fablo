/*
 * License-Identifier: Apache-2.0
 */

'use strict';

const Generator = require('yeoman-generator');
module.exports = class extends Generator {

    async writing() {
        const rootOrganization = await this.config.get('root');
        this.fs.copyTpl(
            this.templatePath('network/docker-compose-base.yaml'),
            this.destinationPath('network-compose/docker-compose.yaml'),
            {
                root: {
                    name: rootOrganization.organization.name,
                    domain: rootOrganization.organization.domain,
                    ca: {
                        name: rootOrganization.ca.prefix
                    },
                    orderer: {
                        name: rootOrganization.orderer.prefix,
                    }
                },

                "orgs": ["gpw", "knf", "zaiks"]
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
