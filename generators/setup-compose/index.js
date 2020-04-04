/*
 * License-Identifier: Apache-2.0
 */

const Generator = require('yeoman-generator');
const utils = require('../utils');

const supportedFabricVersions = ['1.4.3', '1.4.4'];
const supportFabrikkaVersions = ['alpha-0.0.1'];

module.exports = class extends Generator {

    async initializing() {
        this.log(utils.splashScreen());
    }

    constructor(args, opts) {
        super(args, opts);
        this.argument("fabrikkaConfig", {
            type: String,
            required: true,
            description: "Name of fabrikka config file in current dir"
        });

        const configFilePath = this._getConfigsFullPath(this.options.fabrikkaConfig);
        const fileExists = this.fs.exists(configFilePath);

        if (!fileExists) {
            this.emit('error', new Error(`No file under path: ${configFilePath}`));
        } else {
            this.options.fabrikkaConfigPath = configFilePath;
        }
    }

    async writing() {
        const thisGenerator = this;
        const networkConfig = this.fs.readJSON(this.options.fabrikkaConfigPath);

        this._validateFabrikkaVersion(networkConfig.fabrikkaVersion);
        this._validateFabricVersion(networkConfig.networkSettings.fabricVersion);
        this._validateOrderer(networkConfig.rootOrg.orderer);

        this.log("Used network config: " + this.options.fabrikkaConfigPath);
        this.log("Fabric version is: " + networkConfig.networkSettings.fabricVersion);
        this.log("Generating docker-compose network...");

        const capabilities = this._getNetworkCapabilities(networkConfig.networkSettings.fabricVersion);

        // ======= fabric-config =======================================================================================

        this.fs.copyTpl(
            this.templatePath('fabric-config/crypto-config-root.yaml'),
            this.destinationPath('fabric-config/crypto-config-root.yaml'),
            {rootOrg: networkConfig.rootOrg}
        );

        const generator = this;
        networkConfig.orgs.forEach(function (org) {
            generator.fs.copyTpl(
                generator.templatePath('fabric-config/crypto-config-org.yaml'),
                generator.destinationPath(`fabric-config/crypto-config-${org.organization.name.toLowerCase()}.yaml`),
                {org},
            );
        });

        this.fs.copyTpl(
            this.templatePath('fabric-config/configtx.yaml'),
            this.destinationPath('fabric-config/configtx.yaml'),
            {
                capabilities: capabilities,
                networkSettings: networkConfig.networkSettings,
                rootOrg: networkConfig.rootOrg,
                orgs: networkConfig.orgs,
            },
        );

        this.fs.copyTpl(
            this.templatePath('fabric-config/.gitignore'),
            this.destinationPath('fabric-config/.gitignore')
        );

        // ======= fabric-compose ======================================================================================

        this.fs.copyTpl(
            this.templatePath('fabric-compose/.env'),
            this.destinationPath('fabric-compose/.env'),
            {
                networkSettings: networkConfig.networkSettings,
                orgs: networkConfig.orgs,
            },
        );

        this.fs.copyTpl(
            this.templatePath('fabric-compose/docker-compose.yaml'),
            this.destinationPath('fabric-compose/docker-compose.yaml'),
            {
                networkSettings: networkConfig.networkSettings,
                rootOrg: thisGenerator._transformRootOrg(networkConfig.rootOrg),
                orgs: networkConfig.orgs,
            },
        );

        // ======= scripts =============================================================================================

        this.fs.copyTpl(
            this.templatePath('fabric-compose.sh'),
            this.destinationPath('fabric-compose.sh')
        );

        this.fs.copyTpl(
            this.templatePath('fabric-compose/scripts/cli/channel_fns.sh'),
            this.destinationPath('fabric-compose/scripts/cli/channel_fns.sh')
        );

        this.fs.copyTpl(
            this.templatePath('fabric-compose/scripts/cli/channel_fns.sh'),
            this.destinationPath('fabric-compose/scripts/cli/channel_fns.sh')
        );

        this.fs.copyTpl(
            this.templatePath('fabric-compose/scripts/base-functions.sh'),
            this.destinationPath('fabric-compose/scripts/base-functions.sh')
        );

        this.fs.copyTpl(
            this.templatePath('fabric-compose/scripts/base-help.sh'),
            this.destinationPath('fabric-compose/scripts/base-help.sh')
        );

        const transformedChannels = networkConfig.channels.map(function (channel) {
            const orgKeys = channel.orgs.map(o => o.key);
            const orgPeers = channel.orgs.map(o => o.peers).reduce(thisGenerator._flatten);
            const orgsForChannel = networkConfig.orgs
                .filter(o => orgKeys.includes(o.organization.key))
                .map(o => thisGenerator._transformToShortened(o))
                .map(o => thisGenerator._filterToAvailablePeers(o, orgPeers));

            return {
                key: channel.key,
                name: channel.name,
                orgs: orgsForChannel
            }
        });

        this.fs.copyTpl(
            this.templatePath('fabric-compose/scripts/commands-generated.sh'),
            this.destinationPath('fabric-compose/scripts/commands-generated.sh'),
            {
                networkSettings: networkConfig.networkSettings,
                rootOrg: thisGenerator._transformRootOrg(networkConfig.rootOrg),
                orgs: networkConfig.orgs,
                channels: transformedChannels,
            },
        );

        this.on('end', function () {
            this.log("Done & done !!! Try the network out: ");
            this.log("-> fabric-compose.sh up - to start network");
            this.log("-> fabric-compose.sh help - to view all commands");
        });
    }

    _transformRootOrg(rootOrg) {
        const orderersExtended = this._extendOrderers(rootOrg.orderer, rootOrg.organization.domain);
        const ordererHead = orderersExtended.slice(0, 1).reduce(this._flatten);
        return {
            organization: rootOrg.organization,
            ca: rootOrg.ca,
            orderers: orderersExtended,
            ordererHead: ordererHead
        }
    }

    _extendOrderers(orderer, domain) {
        return Array(orderer.instances).fill().map((x, i) => i).map(function (i) {
            const name = `${orderer.prefix}` + i;
            return {
                name: name,
                address: `${name}.${domain}`
            };
        });
    }

    _transformToShortened(org) {
        return {
            name: org.organization.name,
            mspName: org.organization.mspName,
            domain: org.organization.domain,
            peers: this._extendPeers(org.peer, org.organization.domain)
        }
    }

    _filterToAvailablePeers(shortenedOrg, availablePeers) {
        const filteredPeers = shortenedOrg.peers.filter(p => availablePeers.includes(p.name));
        return {
            name: shortenedOrg.name,
            mspName: shortenedOrg.mspName,
            domain: shortenedOrg.domain,
            peers: filteredPeers
        }
    }

    _extendPeers(peer, domain) {
        return Array(peer.instances).fill().map((x, i) => i).map(function (i) {
            return {
                name: "peer" + i,
                address: `peer${i}.${domain}`
            };
        });
    }

    _validateFabrikkaVersion(fabrikkaVersion) {
        this._validationBase(
            !supportFabrikkaVersions.includes(fabrikkaVersion),
            `Fabrikka's ${fabrikkaVersion} version is not supported. Supported versions are: ${supportFabrikkaVersions}`
        );
    }

    _validateFabricVersion(fabricVersion) {
        this._validationBase(
            !supportedFabricVersions.includes(fabricVersion),
            `Fabric's ${fabricVersion} version is not supported. Supported versions are: ${supportedFabricVersions}`
        );
    }

    _validateOrderer(orderer) {
        this._validationBase(
            (orderer.consensus === "solo" && orderer.instances > 1),
            `Orderer consesus type is set to 'solo', but number of instances is ${orderer.instances}. Only one instance is needed :).`
        )
    }

    _getNetworkCapabilities(fabricVersion) {
        switch (fabricVersion) {
            case '1.4.3':
                return {channel: "V1_4_3", orderer: "V1_4_2", application: "V1_4_2"};
            default:
                return {channel: "V1_4_2", orderer: "V1_4_2", application: "V1_4_2"};
        }
    }

    _getConfigsFullPath(configFile) {
        const currentPath = this.env.cwd;
        return currentPath + "/" + configFile;
    }

    _validationBase(condition, errorMessage) {
        if (condition) {
            this.emit('error', new Error(errorMessage));
        }
    }

    _flatten(prev, curr) {
        return prev.concat(curr);
    }
};
