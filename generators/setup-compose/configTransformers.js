const fs = require('fs');

function flatten(prev, curr) {
  return prev.concat(curr);
}

function getFullPathOf(configFile, env) {
  const currentPath = env.cwd;
  return `${currentPath}/${configFile}`;
}


function transformChaincodesConfig(chaincodes, transformedChannels, yeomanEnv) {
  return chaincodes.map((chaincode) => {
    const matchingChannel = transformedChannels
      .filter((c) => c.key === chaincode.channel)
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
      endorsement: chaincode.endorsement,
      chaincodePathExists,
    };
  });
}

function transformOrdererType(ordererTypeJsonConfigFormat) {
  let consensusType = ordererTypeJsonConfigFormat
  if (consensusType === 'raft') {
    consensusType = 'etcdraft';
  }
  return consensusType;
}

function transformOrderersConfig(ordererJsonConfigFormat, rootDomainJsonConfigFormat) {
  let type = transformOrdererType(ordererJsonConfigFormat.type);

  return Array(ordererJsonConfigFormat.instances).fill().map((x, i) => i).map((i) => {
    const name = `${ordererJsonConfigFormat.prefix}${i}`;
    return {
      name,
      address: `${name}.${rootDomainJsonConfigFormat}`,
      domain: rootDomainJsonConfigFormat,
      consensus: type,
    };
  });
}


function transformRootOrgConfig(rootOrgJsonConfigFormat) {
  const orderersExtended = transformOrderersConfig(
    rootOrgJsonConfigFormat.orderer,
    rootOrgJsonConfigFormat.organization.domain,
  );
  const ordererHead = orderersExtended.slice(0, 1).reduce(flatten);
  return {
    organization: rootOrgJsonConfigFormat.organization,
    ca: rootOrgJsonConfigFormat.ca,
    orderers: orderersExtended,
    ordererHead,
  };
}

function extendPeers(peerJsonFormat, domainJsonFormat) {
  return Array(peerJsonFormat.instances).fill().map((x, i) => i).map((i) => ({
    name: `peer${i}`,
    address: `peer${i}.${domainJsonFormat}`,
  }));
}

function transformOrgConfig(orgJsonConfigFormat) {
  const orgsCryptoConfigFileName = `crypto-config-${orgJsonConfigFormat.organization.name.toLowerCase()}`;
  return {
    name: orgJsonConfigFormat.organization.name,
    mspName: orgJsonConfigFormat.organization.mspName,
    domain: orgJsonConfigFormat.organization.domain,
    peers: extendPeers(orgJsonConfigFormat.peer, orgJsonConfigFormat.organization.domain),
    peersCount: orgJsonConfigFormat.peer.instances,
    cryptoConfigFileName: orgsCryptoConfigFileName,
  };
}

function filterToAvailablePeers(orgTransformedFormat, peersTransformedFormat) {
  const filteredPeers = orgTransformedFormat.peers.filter(
    (p) => peersTransformedFormat.includes(p.name),
  );
  return {
    name: orgTransformedFormat.name,
    mspName: orgTransformedFormat.mspName,
    domain: orgTransformedFormat.domain,
    peers: filteredPeers,
  };
}

function transformChannelConfig(channelJsonConfigFormat, orgsJsonConfigFormat) {
  const orgKeys = channelJsonConfigFormat.orgs.map((o) => o.key);
  const orgPeers = channelJsonConfigFormat.orgs.map((o) => o.peers).reduce(flatten);
  const orgsForChannel = orgsJsonConfigFormat
    .filter((o) => orgKeys.includes(o.organization.key))
    .map((o) => transformOrgConfig(o))
    .map((o) => filterToAvailablePeers(o, orgPeers));

  return {
    key: channelJsonConfigFormat.key,
    name: channelJsonConfigFormat.name,
    orgs: orgsForChannel,
  };
}

function getNetworkCapabilities(fabricVersion) {
  //Used https://github.com/hyperledger/fabric/blob/v1.4.8/sampleconfig/configtx.yaml for values
  switch (fabricVersion) {
    case '1.4.8':
      return { channel: 'V1_4_3', orderer: 'V1_4_2', application: 'V1_4_2' };
    case '1.4.7':
      return { channel: 'V1_4_3', orderer: 'V1_4_2', application: 'V1_4_2' };
    case '1.4.6':
      return { channel: 'V1_4_3', orderer: 'V1_4_2', application: 'V1_4_2' };
    case '1.4.5':
      return { channel: 'V1_4_3', orderer: 'V1_4_2', application: 'V1_4_2' };
    case '1.4.4':
      return { channel: 'V1_4_3', orderer: 'V1_4_2', application: 'V1_4_2' };
    case '1.4.3':
      return { channel: 'V1_4_3', orderer: 'V1_4_2', application: 'V1_4_2' };
    case '1.4.2':
      return { channel: 'V1_4_2', orderer: 'V1_4_2', application: 'V1_4_2' };
    case '1.4.1':
      return { channel: 'V1_3', orderer: 'V1_1', application: 'V1_3' };
    case '1.4.0':
      return { channel: 'V1_3', orderer: 'V1_1', application: 'V1_3' };
    case '1.3.0':
      return { channel: 'V1_3', orderer: 'V1_1', application: 'V1_3' };
    default:
      return { channel: 'V1_4_3', orderer: 'V1_4_2', application: 'V1_4_2' };
  }
}

module.exports = {
  transformChaincodesConfig,
  transformRootOrgConfig,
  transformOrgConfig,
  transformChannelConfig,
  getNetworkCapabilities,
};
