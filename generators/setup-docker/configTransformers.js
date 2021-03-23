const _ = require('lodash');

function singleOrListString(items) {
  if (items.length === 1) {
    return items[0];
  }
  return `"${items.join(' ')}"`;
}

function transformChaincodesConfig(chaincodes, transformedChannels) {
  return chaincodes.map((chaincode) => {
    const matchingChannel = transformedChannels.find((c) => c.key === chaincode.channel);
    return {
      directory: chaincode.directory,
      name: chaincode.name,
      version: chaincode.version,
      lang: chaincode.lang,
      channel: matchingChannel,
      init: chaincode.init,
      endorsement: chaincode.endorsement,
      instantiatingOrg: matchingChannel.instantiatingOrg,
    };
  });
}

function transformOrderersConfig(ordererJsonConfigFormat, rootDomainJsonConfigFormat) {
  const type = ordererJsonConfigFormat.type === 'raft' ? 'etcdraft' : ordererJsonConfigFormat.type;

  return Array(ordererJsonConfigFormat.instances)
    .fill()
    .map((x, i) => i)
    .map((i) => {
      const name = `${ordererJsonConfigFormat.prefix}${i}`;
      const address = `${name}.${rootDomainJsonConfigFormat}`;
      const port = 7050 + i;
      return {
        name,
        domain: rootDomainJsonConfigFormat,
        address,
        consensus: type,
        port,
        fullAddress: `${address}:${port}`,
      };
    });
}

function transformCaConfig(caJsonFormat, orgName, orgDomainJsonFormat, caExposePort) {
  const address = `${caJsonFormat.prefix}.${orgDomainJsonFormat}`;
  const port = 7054;
  return {
    prefix: caJsonFormat.prefix,
    address,
    port,
    exposePort: caExposePort,
    fullAddress: `${address}:${port}`,
    caAdminNameVar: `${orgName.toUpperCase()}_CA_ADMIN_NAME`,
    caAdminPassVar: `${orgName.toUpperCase()}_CA_ADMIN_PASSWORD`,
  };
}

function transformRootOrgConfig(rootOrgJsonFormat) {
  const { domain } = rootOrgJsonFormat.organization;
  const orderersExtended = transformOrderersConfig(
    rootOrgJsonFormat.orderer,
    domain,
  );
  const ordererHead = orderersExtended[0];
  return {
    name: rootOrgJsonFormat.organization.name,
    mspName: rootOrgJsonFormat.organization.mspName,
    domain,
    organization: rootOrgJsonFormat.organization,
    ca: transformCaConfig(rootOrgJsonFormat.ca, rootOrgJsonFormat.organization.name, domain, 7030),
    orderers: orderersExtended,
    ordererHead,
  };
}

function extendPeers(peerJsonFormat, domainJsonFormat, headPeerPort, headPeerCouchDbExposePort) {
  let { anchorPeerInstances } = peerJsonFormat;
  if (typeof anchorPeerInstances === 'undefined' || anchorPeerInstances === null) {
    anchorPeerInstances = 1;
  }
  return Array(peerJsonFormat.instances)
    .fill()
    .map((x, i) => i)
    .map((i) => {
      const address = `peer${i}.${domainJsonFormat}`;
      const port = headPeerPort + i;
      return {
        name: `peer${i}`,
        address,
        db: peerJsonFormat.db,
        isAnchorPeer: i < anchorPeerInstances,
        port,
        fullAddress: `${address}:${port}`,
        couchDbExposePort: headPeerCouchDbExposePort + i,
      };
    });
}

function transformOrgConfig(orgJsonFormat, orgNumber) {
  const orgsCryptoConfigFileName = `crypto-config-${orgJsonFormat.organization.name.toLowerCase()}`;
  const headPeerPort = 7060 + 10 * orgNumber;
  const headPeerCouchDbExposePort = 5080 + 10 * orgNumber;
  const caExposePort = 7031 + orgNumber;
  const orgName = orgJsonFormat.organization.name;
  const orgDomain = orgJsonFormat.organization.domain;

  const peersExtended = extendPeers(
    orgJsonFormat.peer,
    orgDomain,
    headPeerPort,
    headPeerCouchDbExposePort,
  );
  const anchorPeers = peersExtended.filter((p) => p.isAnchorPeer);
  const bootstrapPeersList = anchorPeers.map((a) => a.fullAddress);

  return {
    key: orgJsonFormat.organization.key,
    name: orgName,
    mspName: orgJsonFormat.organization.mspName,
    domain: orgDomain,
    cryptoConfigFileName: orgsCryptoConfigFileName,
    peersCount: peersExtended.length,
    peers: peersExtended,
    anchorPeers,
    bootstrapPeers: singleOrListString(bootstrapPeersList),
    ca: transformCaConfig(orgJsonFormat.ca, orgName, orgDomain, caExposePort),
    headPeer: peersExtended[0],
  };
}

function transformOrgConfigs(orgsJsonConfigFormat) {
  return orgsJsonConfigFormat.map((org, currentIndex) => transformOrgConfig(org, currentIndex));
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
    headPeer: filteredPeers[0],
  };
}

function transformChannelConfig(channelJsonFormat, orgsTransformed) {
  const channelName = channelJsonFormat.name;

  const orgKeys = channelJsonFormat.orgs.map((o) => o.key);
  const orgPeers = channelJsonFormat.orgs.map((o) => o.peers)
    .reduce((a, b) => a.concat(b), []);
  const orgsForChannel = orgsTransformed
    .filter((org) => orgKeys.includes(org.key))
    .map((org) => filterToAvailablePeers(org, orgPeers));

  return {
    key: channelJsonFormat.key,
    name: channelName,
    orgs: orgsForChannel,
    profile: {
      name: _.chain(channelName).camelCase().upperFirst().value(),
    },
    instantiatingOrg: orgsForChannel[0],
  };
}

function transformChannelConfigs(channelsJsonConfigFormat, orgsTransformed) {
  return channelsJsonConfigFormat.map((ch) => transformChannelConfig(ch, orgsTransformed));
}

// Used https://github.com/hyperledger/fabric/blob/v1.4.8/sampleconfig/configtx.yaml for values
const networkCapabilities = {
  '2.2.1': { channel: 'V1_4_3', orderer: 'V1_4_2', application: 'V1_4_2' },
  '2.2.0': { channel: 'V1_4_3', orderer: 'V1_4_2', application: 'V1_4_2' },
  '2.1.1': { channel: 'V1_4_3', orderer: 'V1_4_2', application: 'V1_4_2' },
  '2.1.0': { channel: 'V1_4_3', orderer: 'V1_4_2', application: 'V1_4_2' },
  '2.0.1': { channel: 'V1_4_3', orderer: 'V1_4_2', application: 'V1_4_2' },

  '1.4.8': { channel: 'V1_4_3', orderer: 'V1_4_2', application: 'V1_4_2' },
  '1.4.7': { channel: 'V1_4_3', orderer: 'V1_4_2', application: 'V1_4_2' },
  '1.4.6': { channel: 'V1_4_3', orderer: 'V1_4_2', application: 'V1_4_2' },
  '1.4.5': { channel: 'V1_4_3', orderer: 'V1_4_2', application: 'V1_4_2' },
  '1.4.4': { channel: 'V1_4_3', orderer: 'V1_4_2', application: 'V1_4_2' },
  '1.4.3': { channel: 'V1_4_3', orderer: 'V1_4_2', application: 'V1_4_2' },
  '1.4.2': { channel: 'V1_4_2', orderer: 'V1_4_2', application: 'V1_4_2' },
  '1.4.1': { channel: 'V1_3', orderer: 'V1_1', application: 'V1_3' },
  '1.4.0': { channel: 'V1_3', orderer: 'V1_1', application: 'V1_3' },
  '1.3.0': { channel: 'V1_3', orderer: 'V1_1', application: 'V1_3' },
};

function getNetworkCapabilities(fabricVersion) {
  return networkCapabilities[fabricVersion] || networkCapabilities['1.4.8'];
}

function isHlf20(fabricVersion) {
  const supported20Versions = ['2.2.1', '2.2.0', '2.1.1', '2.1.0', '2.0.1'];
  return supported20Versions.includes(fabricVersion);
}

function getCaVersion(fabricVersion) {
  const caVersion = {
    '2.2.1': '1.4.9',
    '2.2.0': '1.4.9',
    '2.1.1': '1.4.9',
    '2.1.0': '1.4.9',
    '2.0.1': '1.4.9',
    '1.4.10': '1.4.9',
    '1.4.11': '1.4.9',
  };
  return caVersion[fabricVersion] || fabricVersion;
}

function getEnvVarOrThrow(name) {
  const value = process.env[name];
  if (!value || !value.length) throw new Error(`Missing environment variable ${name}`);
  return value;
}

function getPathsFromEnv() {
  return {
    fabricaConfig: getEnvVarOrThrow('FABRICA_CONFIG'),
    chaincodesBaseDir: getEnvVarOrThrow('CHAINCODES_BASE_DIR'),
  };
}

module.exports = {
  transformChaincodesConfig,
  transformRootOrgConfig,
  transformOrgConfigs,
  transformChannelConfigs,
  getNetworkCapabilities,
  getCaVersion,
  getPathsFromEnv,
  isHlf20,
};
