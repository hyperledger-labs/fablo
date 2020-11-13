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

function transformRootOrgConfig(rootOrgJsonConfigFormat) {
  const orderersExtended = transformOrderersConfig(
    rootOrgJsonConfigFormat.orderer,
    rootOrgJsonConfigFormat.organization.domain,
  );
  const ordererHead = orderersExtended[0];
  return {
    organization: rootOrgJsonConfigFormat.organization,
    ca: rootOrgJsonConfigFormat.ca,
    orderers: orderersExtended,
    ordererHead,
  };
}

function extendPeers(peerJsonFormat, domainJsonFormat) {
  return Array(peerJsonFormat.instances)
    .fill()
    .map((x, i) => i)
    .map((i) => ({
      name: `peer${i}`,
      address: `peer${i}.${domainJsonFormat}`,
    }));
}

function extendAnchorPeers(peerJsonFormat, domainJsonFormat) {
  let { anchorPeerInstances } = peerJsonFormat;
  if (typeof anchorPeerInstances === 'undefined' || anchorPeerInstances === null) {
    anchorPeerInstances = 1;
  }
  return Array(anchorPeerInstances)
    .fill()
    .map((x, i) => i)
    .map((i) => ({
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
    anchorPeers: extendAnchorPeers(
      orgJsonConfigFormat.peer,
      orgJsonConfigFormat.organization.domain,
    ),
    peersCount: orgJsonConfigFormat.peer.instances,
    cryptoConfigFileName: orgsCryptoConfigFileName,
  };
}

function transformOrgConfigs(orgsJsonConfigFormat) {
  return orgsJsonConfigFormat.map((o) => transformOrgConfig(o));
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
  const orgPeers = channelJsonConfigFormat.orgs.map((o) => o.peers)
    .reduce((a, b) => a.concat(b), []);
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

function transformChannelConfigs(channelsJsonConfigFormat, orgsJsonConfigFormat) {
  return channelsJsonConfigFormat.map((ch) => transformChannelConfig(ch, orgsJsonConfigFormat));
}

function getNetworkCapabilities(fabricVersion) {
  // Used https://github.com/hyperledger/fabric/blob/v1.4.8/sampleconfig/configtx.yaml for values
  const networkCapabilities = {
    '2.2.1': {
      channel: 'V1_4_3',
      orderer: 'V1_4_2',
      application: 'V1_4_2',
    },
    '2.2.0': {
      channel: 'V1_4_3',
      orderer: 'V1_4_2',
      application: 'V1_4_2',
    },
    '2.1.1': {
      channel: 'V1_4_3',
      orderer: 'V1_4_2',
      application: 'V1_4_2',
    },
    '2.1.0': {
      channel: 'V1_4_3',
      orderer: 'V1_4_2',
      application: 'V1_4_2',
    },
    '2.0.1': {
      channel: 'V1_4_3',
      orderer: 'V1_4_2',
      application: 'V1_4_2',
    },

    '1.4.8': {
      channel: 'V1_4_3',
      orderer: 'V1_4_2',
      application: 'V1_4_2',
    },
    '1.4.7': {
      channel: 'V1_4_3',
      orderer: 'V1_4_2',
      application: 'V1_4_2',
    },
    '1.4.6': {
      channel: 'V1_4_3',
      orderer: 'V1_4_2',
      application: 'V1_4_2',
    },
    '1.4.5': {
      channel: 'V1_4_3',
      orderer: 'V1_4_2',
      application: 'V1_4_2',
    },
    '1.4.4': {
      channel: 'V1_4_3',
      orderer: 'V1_4_2',
      application: 'V1_4_2',
    },
    '1.4.3': {
      channel: 'V1_4_3',
      orderer: 'V1_4_2',
      application: 'V1_4_2',
    },
    '1.4.2': {
      channel: 'V1_4_2',
      orderer: 'V1_4_2',
      application: 'V1_4_2',
    },
    '1.4.1': {
      channel: 'V1_3',
      orderer: 'V1_1',
      application: 'V1_3',
    },
    '1.4.0': {
      channel: 'V1_3',
      orderer: 'V1_1',
      application: 'V1_3',
    },
    '1.3.0': {
      channel: 'V1_3',
      orderer: 'V1_1',
      application: 'V1_3',
    },
  };
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
