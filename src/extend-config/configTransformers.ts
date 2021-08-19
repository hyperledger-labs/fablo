import * as _ from "lodash";
import { version } from "../repositoryUtils";
import defaults from "./defaults";
import {
  CAJson,
  ChaincodeJson,
  ChannelJson,
  NetworkSettingsJson,
  OrdererJson,
  OrgJson,
  PeerJson,
  RootOrgJson,
} from "../types/FabricaConfigJson";
import {
  CAConfig,
  Capabilities,
  ChaincodeConfig,
  ChannelConfig,
  FabricVersions,
  NetworkSettings,
  OrdererConfig,
  OrgConfig,
  PeerConfig,
  PrivateCollectionConfig,
  RootOrgConfig,
} from "../types/FabricaConfigExtended";

const createPrivateCollectionConfig = (
  fabricVersion: string,
  channel: ChannelConfig,
  name: string,
  orgNames: string[],
): PrivateCollectionConfig => {
  // We need only orgs that can have access to private data
  const relevantOrgs = (channel.orgs || []).filter((o) => !!orgNames.find((n) => n === o.name));
  if (relevantOrgs.length < orgNames.length) {
    throw new Error(`Cannot find all orgs for names ${orgNames}`);
  }

  const policy = `OR(${relevantOrgs.map((o) => `'${o.mspName}.member'`).join(",")})`;
  const peerCounts = relevantOrgs.map((o) => (o.anchorPeers || []).length);
  const maxPeerCount = peerCounts.reduce((a, b) => a + b, 0);
  const requiredPeerCount = peerCounts.reduce((a, b) => Math.min(a, b), maxPeerCount) || 1;

  const memberOnlyRead = version(fabricVersion).isGreaterOrEqual("1.4.0") ? { memberOnlyRead: true } : {};
  const memberOnlyWrite = version(fabricVersion).isGreaterOrEqual("2.0.0") ? { memberOnlyWrite: true } : {};

  return {
    name,
    policy,
    requiredPeerCount,
    maxPeerCount,
    blockToLive: 0,
    ...memberOnlyRead,
    ...memberOnlyWrite,
  };
};

const transformChaincodesConfig = (
  fabricVersion: string,
  chaincodes: ChaincodeJson[],
  transformedChannels: ChannelConfig[],
  capabilities: Capabilities,
): ChaincodeConfig[] => {
  return chaincodes.map((chaincode) => {
    const channel = transformedChannels.find((c) => c.name === chaincode.channel);
    if (!channel) throw new Error(`No matching channel with name '${chaincode.channel}'`);

    const initParams: { initRequired: boolean } | { init: string } = capabilities.isV2
      ? { initRequired: chaincode.initRequired || defaults.chaincode.initRequired }
      : { init: chaincode.init || defaults.chaincode.init };

    const endorsement = chaincode.endorsement ?? defaults.chaincode.endorsement(channel.orgs, capabilities);

    const privateData = (chaincode.privateData ?? []).map((d) =>
      createPrivateCollectionConfig(fabricVersion, channel, d.name, d.orgNames),
    );
    const privateDataConfigFile = privateData.length > 0 ? `collections/${chaincode.name}.json` : undefined;

    return {
      directory: chaincode.directory,
      name: chaincode.name,
      version: chaincode.version,
      lang: chaincode.lang,
      channel,
      ...initParams,
      endorsement,
      instantiatingOrg: channel.instantiatingOrg,
      privateDataConfigFile,
      privateData,
    };
  });
};

const transformOrderersConfig = (ordererJson: OrdererJson, rootDomainJson: string): OrdererConfig[] => {
  const consensus = ordererJson.type === "raft" ? "etcdraft" : ordererJson.type;
  const prefix = ordererJson.prefix ?? defaults.orderer.prefix;

  return Array(ordererJson.instances)
    .fill(undefined)
    .map((_x, i) => {
      const name = `${prefix}${i}`;
      const address = `${name}.${rootDomainJson}`;
      const port = 7050 + i;
      return {
        name,
        domain: rootDomainJson,
        address,
        consensus,
        port,
        fullAddress: `${address}:${port}`,
      };
    });
};

const transformCaConfig = (
  caJsonFormat: CAJson,
  orgName: string,
  orgDomainJsonFormat: string,
  caExposePort: number,
): CAConfig => {
  const ca = caJsonFormat || defaults.ca;
  const address = `${ca.prefix}.${orgDomainJsonFormat}`;
  const port = 7054;
  return {
    prefix: ca.prefix,
    address,
    port,
    exposePort: caExposePort,
    fullAddress: `${address}:${port}`,
    caAdminNameVar: `${orgName.toUpperCase()}_CA_ADMIN_NAME`,
    caAdminPassVar: `${orgName.toUpperCase()}_CA_ADMIN_PASSWORD`,
  };
};

const transformRootOrgConfig = (rootOrgJsonFormat: RootOrgJson): RootOrgConfig => {
  const { domain, name } = rootOrgJsonFormat.organization;
  const mspName = rootOrgJsonFormat.organization.mspName || defaults.organization.mspName(name);
  const orderersExtended = transformOrderersConfig(rootOrgJsonFormat.orderer, domain);
  const ordererHead = orderersExtended[0];
  return {
    name,
    mspName,
    domain,
    ca: transformCaConfig(rootOrgJsonFormat.ca, rootOrgJsonFormat.organization.name, domain, 7030),
    orderers: orderersExtended,
    ordererHead,
  };
};

const extendPeers = (
  peerJsonFormat: PeerJson,
  domainJsonFormat: string,
  headPeerPort: number,
  headPeerCouchDbExposePort: number,
): PeerConfig[] => {
  const peerPrefix = peerJsonFormat.prefix || defaults.peer.prefix;
  const db = peerJsonFormat.db || defaults.peer.db;
  const anchorPeerInstances = peerJsonFormat.anchorPeerInstances || defaults.peer.anchorPeerInstances;

  return Array(peerJsonFormat.instances)
    .fill(undefined)
    .map((_x, i) => {
      const address = `${peerPrefix}${i}.${domainJsonFormat}`;
      const port = headPeerPort + i;
      return {
        name: `${peerPrefix}${i}`,
        address,
        db,
        isAnchorPeer: i < anchorPeerInstances,
        port,
        fullAddress: `${address}:${port}`,
        couchDbExposePort: headPeerCouchDbExposePort + i,
      };
    });
};

const transformOrgConfig = (orgJsonFormat: OrgJson, orgIndex: number): OrgConfig => {
  const cryptoConfigFileName = `crypto-config-${orgJsonFormat.organization.name.toLowerCase()}`;
  const headPeerPort = 7060 + 10 * orgIndex;
  const headPeerCouchDbPort = 5080 + 10 * orgIndex;
  const caPort = 7031 + orgIndex;
  const { domain, name } = orgJsonFormat.organization;
  const mspName = orgJsonFormat.organization.mspName || defaults.organization.mspName(name);
  const peers = extendPeers(orgJsonFormat.peer, domain, headPeerPort, headPeerCouchDbPort);
  const anchorPeers = peers.filter((p) => p.isAnchorPeer);
  const bootstrapPeersList = anchorPeers.map((a) => a.fullAddress);
  const bootstrapPeersStringParam =
    bootstrapPeersList.length === 1
      ? bootstrapPeersList[0] // note no quotes in parameter
      : `"${bootstrapPeersList.join(" ")}"`;

  return {
    name,
    mspName,
    domain,
    cryptoConfigFileName,
    peersCount: peers.length,
    peers,
    anchorPeers,
    bootstrapPeers: bootstrapPeersStringParam,
    ca: transformCaConfig(orgJsonFormat.ca, name, domain, caPort),
    cli: {
      address: `cli.${orgJsonFormat.organization.domain}`,
    },
    headPeer: peers[0],
  };
};

const transformOrgConfigs = (orgsJsonConfigFormat: OrgJson[]): OrgConfig[] =>
  orgsJsonConfigFormat.map(transformOrgConfig);

const filterToAvailablePeers = (orgTransformedFormat: OrgConfig, peersTransformedFormat: string[]) => {
  const filteredPeers = orgTransformedFormat.peers.filter((p) => peersTransformedFormat.includes(p.name));
  return {
    ...orgTransformedFormat,
    peers: filteredPeers,
    headPeer: filteredPeers[0],
  };
};

const transformChannelConfig = (channelJsonFormat: ChannelJson, orgsTransformed: OrgConfig[]) => {
  const channelName = channelJsonFormat.name;
  const profileName = _.chain(channelName).camelCase().upperFirst().value();

  const orgNames = channelJsonFormat.orgs.map((o) => o.name);
  const orgPeers = channelJsonFormat.orgs.map((o) => o.peers).reduce((a, b) => a.concat(b), []);
  const orgsForChannel = orgsTransformed
    .filter((org) => orgNames.includes(org.name))
    .map((org) => filterToAvailablePeers(org, orgPeers));

  return {
    name: channelName,
    orgs: orgsForChannel,
    profile: {
      name: profileName,
    },
    instantiatingOrg: orgsForChannel[0],
  };
};

const transformChannelConfigs = (
  channelsJsonConfigFormat: ChannelJson[],
  orgsTransformed: OrgConfig[],
): ChannelConfig[] => channelsJsonConfigFormat.map((ch) => transformChannelConfig(ch, orgsTransformed));

// Used https://github.com/hyperledger/fabric/blob/v1.4.8/sampleconfig/configtx.yaml for values
const getNetworkCapabilities = (fabricVersion: string): Capabilities => {
  if (version(fabricVersion).isGreaterOrEqual("2.0.0"))
    return { channel: "V2_0", orderer: "V2_0", application: "V2_0", isV2: true };

  if (version(fabricVersion).isGreaterOrEqual("1.4.3"))
    return { channel: "V1_4_3", orderer: "V1_4_2", application: "V1_4_2", isV2: false };

  if (version(fabricVersion).isGreaterOrEqual("1.4.2"))
    return { channel: "V1_4_2", orderer: "V1_4_2", application: "V1_4_2", isV2: false };

  return { channel: "V1_3", orderer: "V1_1", application: "V1_3", isV2: false };
};

const getVersions = (fabricVersion: string): FabricVersions => {
  const fabricJavaenvExceptions: Record<string, string> = {
    "1.4.5": "1.4.4",
    "1.4.9": "1.4.8",
    "1.4.10": "1.4.8",
    "1.4.11": "1.4.8",
    "1.4.12": "1.4.8",
    "2.2.2": "2.2.1",
    "2.2.3": "2.2.1",
    "2.3.1": "2.3.0",
    "2.3.2": "2.3.0",
  };

  return {
    fabricVersion,
    fabricCaVersion: version(fabricVersion).isGreaterOrEqual("1.4.10") ? "1.5.0" : fabricVersion,
    fabricCcenvVersion: fabricVersion,
    fabricBaseosVersion: version(fabricVersion).isGreaterOrEqual("2.0") ? fabricVersion : "0.4.9",
    fabricJavaenvVersion: fabricJavaenvExceptions[fabricVersion] ?? fabricVersion,
  };
};

const getEnvVarOrThrow = (name: string): string => {
  const value = process.env[name];
  if (!value || !value.length) throw new Error(`Missing environment variable ${name}`);
  return value;
};

const getPathsFromEnv = () => ({
  fabricaConfig: getEnvVarOrThrow("FABRICA_CONFIG"),
  chaincodesBaseDir: getEnvVarOrThrow("CHAINCODES_BASE_DIR"),
});

const transformNetworkSettings = (networkSettingsJson: NetworkSettingsJson): NetworkSettings => {
  const monitoring = {
    loglevel: networkSettingsJson?.monitoring?.loglevel || defaults.networkSettings.monitoring.loglevel,
  };

  return {
    ...networkSettingsJson,
    ...getVersions(networkSettingsJson.fabricVersion),
    paths: getPathsFromEnv(),
    monitoring,
  };
};

export {
  transformChaincodesConfig,
  transformRootOrgConfig,
  transformOrgConfigs,
  transformChannelConfigs,
  getNetworkCapabilities,
  transformNetworkSettings,
};
