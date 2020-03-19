/*
 * License-Identifier: Apache-2.0
 */


const Generator = require('yeoman-generator');

module.exports = class extends Generator {
  async writing() {
    const rootOrg = await this.config.get('root');
    const orgs = await this.config.get('orgs');

    this.fs.copyTpl(
      this.templatePath('network/network-compose/docker-compose-base.yml'),
      this.destinationPath('network/network-compose/docker-compose.yml'),
      {
        root: {
          name: rootOrg.organization.name,
          domain: rootOrg.organization.domain,
          ca: {
            name: rootOrg.ca.prefix,
          },
          orderer: {
            name: rootOrg.orderer.prefix,
            instances: rootOrg.orderer.instances,
          },
        },
        orgs,
      },
    );

    this.fs.copyTpl(
      this.templatePath('network/network-compose/.env'),
      this.destinationPath('network/network-compose/.env'),
      {
        fabricVersion: '1.4.2',
        orgs,
      },
    );

    this.fs.copyTpl(
      this.templatePath('network/network-config/root-crypto-config.yaml'),
      this.destinationPath('network/network-config/crypto-config-root.yaml'),
      {
        root: {
          key: rootOrg.organization.key,
          name: rootOrg.organization.name,
          domain: rootOrg.organization.domain,
          ca: {
            name: rootOrg.ca.prefix,
          },
          orderer: {
            name: rootOrg.orderer.prefix,
            instances: rootOrg.orderer.instances,
          },
        },
      },
    );

    this.fs.copyTpl(
        this.templatePath('network/network-config/org-crypto-config.yaml'),
        this.destinationPath('network/network-config/crypto-config-org.yaml'),
        {
          root: {
            key: rootOrg.organization.key,
            name: rootOrg.organization.name,
            domain: rootOrg.organization.domain,
            ca: {
              name: rootOrg.ca.prefix,
            },
            orderer: {
              name: rootOrg.orderer.prefix,
              instances: rootOrg.orderer.instances,
            },
          },
        },
    );
  }
};
