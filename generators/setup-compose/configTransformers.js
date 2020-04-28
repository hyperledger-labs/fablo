const fs = require("fs");

function transformChaincodesConfig(chaincodes, transformedChannels, yeomanEnv) {
    return chaincodes.map(function (chaincode) {
        const matchingChannel = transformedChannels
            .filter(c => c.key === chaincode.channel)
            .slice(0, 1)
            .reduce(flatten);
        const chaincodePath = getFullPathOf(chaincode.directory, yeomanEnv);
        const chaincodePathExists = fs.existsSync(chaincodePath);
        return {
            directory: chaincode.directory,
            name: chaincode.name,
            version: chaincode.version,
            lang: chaincode.lang,
            channel: matchingChannel,
            init: chaincode.init,
            endorsment: chaincode.endorsment,
            chaincodePathExists: chaincodePathExists
        }
    });
}

function transformRootOrgConfig(rootOrgJsonConfigFormat) {
    const orderersExtended = transformOrderersConfig(rootOrgJsonConfigFormat.orderer, rootOrgJsonConfigFormat.organization.domain);
    const ordererHead = orderersExtended.slice(0, 1).reduce(flatten);
    return {
        organization: rootOrgJsonConfigFormat.organization,
        ca: rootOrgJsonConfigFormat.ca,
        orderers: orderersExtended,
        ordererHead: ordererHead
    }
}

function transformOrderersConfig(ordererJsonConfigFormat, rootDomainJsonConfigFormat) {
    return Array(ordererJsonConfigFormat.instances).fill().map((x, i) => i).map(function (i) {
        const name = `${ordererJsonConfigFormat.prefix}` + i;
        return {
            name: name,
            address: `${name}.${rootDomainJsonConfigFormat}`,
            consensus: ordererJsonConfigFormat.consensus
        };
    });
}

function transformChannelConfig(channelJsonConfigFormat, orgsJsonConfigFormat) {
    const orgKeys = channelJsonConfigFormat.orgs.map(o => o.key);
    const orgPeers = channelJsonConfigFormat.orgs.map(o => o.peers).reduce(flatten);
    const orgsForChannel = orgsJsonConfigFormat
        .filter(o => orgKeys.includes(o.organization.key))
        .map(o => transformToShortened(o))
        .map(o => filterToAvailablePeers(o, orgPeers));

    return {
        key: channelJsonConfigFormat.key,
        name: channelJsonConfigFormat.name,
        orgs: orgsForChannel
    }
}

function transformToShortened(orgJsonConfigFormat) {
    return {
        name: orgJsonConfigFormat.organization.name,
        mspName: orgJsonConfigFormat.organization.mspName,
        domain: orgJsonConfigFormat.organization.domain,
        peers: extendPeers(orgJsonConfigFormat.peer, orgJsonConfigFormat.organization.domain)
    }
}

function filterToAvailablePeers(orgTransformedFormat, peersTransformedFormat) {
    const filteredPeers = orgTransformedFormat.peers.filter(p => peersTransformedFormat.includes(p.name));
    return {
        name: orgTransformedFormat.name,
        mspName: orgTransformedFormat.mspName,
        domain: orgTransformedFormat.domain,
        peers: filteredPeers
    }
}

function extendPeers(peerJsonFormat, domainJsonFormat) {
    return Array(peerJsonFormat.instances).fill().map((x, i) => i).map(function (i) {
        return {
            name: "peer" + i,
            address: `peer${i}.${domainJsonFormat}`
        };
    });
}

function flatten(prev, curr) {
    return prev.concat(curr);
}

function getFullPathOf(configFile, env) {
    const currentPath = env.cwd;
    return currentPath + "/" + configFile;
}

module.exports = {
    transformChaincodesConfig,
    transformRootOrgConfig,
    transformChannelConfig
};


