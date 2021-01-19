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
      instantiatingOrg: matchingChannel.orgs[0]
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
      return {
        name,
        address: `${name}.${rootDomainJsonConfigFormat}`,
        domain: rootDomainJsonConfigFormat,
        consensus: type,
      };
    });
}

function transformCaConfig(caJsonFormat, orgName, orgDomainJsonFormat) {
  const address = `${caJsonFormat.prefix}.${orgDomainJsonFormat}`
  const port = 7054
  return {
    prefix: caJsonFormat.prefix,
    address,
    port,
    fullAddress: `${address}:${port}`,
    caAdminNameVar: orgName.toUpperCase()+"_CA_ADMIN_NAME",
    caAdminPassVar: orgName.toUpperCase()+"_CA_ADMIN_PASSWORD",
  }
}

function transformRootOrgConfig(rootOrgJsonFormat) {
  const orderersExtended = transformOrderersConfig(
    rootOrgJsonFormat.orderer,
    rootOrgJsonFormat.organization.domain,
  );
  const ordererHead = orderersExtended[0];
  return {
    name: rootOrgJsonFormat.organization.name,
    mspName: rootOrgJsonFormat.organization.mspName,
    domain: rootOrgJsonFormat.organization.domain,
    organization: rootOrgJsonFormat.organization,
    ca: transformCaConfig(rootOrgJsonFormat.ca, rootOrgJsonFormat.organization.name, rootOrgJsonFormat.organization.domain),
    orderers: orderersExtended,
    ordererHead,
  };
}

function extendPeers(peerJsonFormat, domainJsonFormat, peerPortsBeginning) {
  let { anchorPeerInstances } = peerJsonFormat;
  if (typeof anchorPeerInstances === 'undefined' || anchorPeerInstances === null) {
    anchorPeerInstances = 1;
  }
  return Array(peerJsonFormat.instances)
    .fill()
    .map((x, i) => i)
    .map((i) => {
      const address = `peer${i}.${domainJsonFormat}`
      const port = peerPortsBeginning+i
      return {
        name: `peer${i}`,
        address,
        db: peerJsonFormat.db,
        isAnchorPeer: i < anchorPeerInstances,
        port: peerPortsBeginning+i,
        fullAddress: `${address}:${port}`
      }
    });
}

function transformOrgConfig(orgJsonFormat, orgNumber) {
  const orgsCryptoConfigFileName = `crypto-config-${orgJsonFormat.organization.name.toLowerCase()}`;
  const peerPortsBeginning = 7060+10*orgNumber

  const peersExtended = extendPeers(orgJsonFormat.peer, orgJsonFormat.organization.domain, peerPortsBeginning)
  return {
    key: orgJsonFormat.organization.key,
    name: orgJsonFormat.organization.name,
    mspName: orgJsonFormat.organization.mspName,
    domain: orgJsonFormat.organization.domain,
    peers: peersExtended,
    anchorPeers: peersExtended.filter(p => p.isAnchorPeer),
    peersCount: orgJsonFormat.peer.instances,
    cryptoConfigFileName: orgsCryptoConfigFileName,
    ca: transformCaConfig(orgJsonFormat.ca, orgJsonFormat.organization.name, orgJsonFormat.organization.domain)
  };
}

function transformOrgConfigs(orgsJsonConfigFormat) {
  return orgsJsonConfigFormat.map((org, currentIndex) => {
    return transformOrgConfig(org, currentIndex);
  });
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

function transformChannelConfig(channelJsonFormat, orgsTransformed) {
  const orgKeys = channelJsonFormat.orgs.map((o) => o.key);
  const orgPeers = channelJsonFormat.orgs.map((o) => o.peers)
    .reduce((a, b) => a.concat(b), []);
  const orgsForChannel = orgsTransformed
    .filter((org) => orgKeys.includes(org.key))
    .map((org) => filterToAvailablePeers(org, orgPeers));

  return {
    key: channelJsonFormat.key,
    name: channelJsonFormat.name,
    orgs: orgsForChannel,
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
    fabrikkaConfig: getEnvVarOrThrow('FABRIKKA_CONFIG'),
    chaincodesBaseDir: getEnvVarOrThrow('CHAINCODES_BASE_DIR'),
    fabrikkaNetworkRoot: getEnvVarOrThrow('FABRIKKA_NETWORK_ROOT'),
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
