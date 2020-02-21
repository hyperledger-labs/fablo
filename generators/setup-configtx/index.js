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
            this.templatePath('config/configtx-base.yaml'),
            this.destinationPath('network-config/configtx.yaml'),
            {
                root: {
                    mspId: rootOrg.organization.key,
                    name: rootOrg.organization.name,
                    domain: rootOrg.organization.domain,
                    ca: {
                        name: rootOrg.ca.prefix
                    },
                    orderer: {
                        name: rootOrg.orderer.prefix,
                        instances: rootOrg.orderer.instances,
                    }
                },
                orgs: orgs
            }
        );
    }

};
