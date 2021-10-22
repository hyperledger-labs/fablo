import defaults from "./defaults";
import { CAJson, OrdererJson, OrdererOrgJson, OrgJson, PeerJson, RootOrgJson } from "../types/FabloConfigJson";
import {
  CAConfig,
  FabloRestConfig,
  FabloRestLoggingConfig,
  NetworkSettings,
  OrdererConfig,
  OrdererOrgConfig,
  OrgConfig,
  PeerConfig,
  RootOrgConfig,
} from "../types/FabloConfigExtended";

const extendCaConfig = (
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

const getPortsForOrdererOrg = (ordererOrgIndex: number) => ({
  caPort: 7020 + 10 * ordererOrgIndex,
  headOrdererPort: 7021 + 10 * ordererOrgIndex,
});

const extendOrderersConfig = (
  headOrdererPort: number,
  ordererJson: OrdererJson,
  ordererOrgDomainJson: string,
): OrdererConfig[] => {
  const consensus = ordererJson.type === "raft" ? "etcdraft" : ordererJson.type;
  const prefix = ordererJson.prefix ?? defaults.orderer.prefix;

  return Array(ordererJson.instances)
    .fill(undefined)
    .map((_x, i) => {
      const name = `${prefix}${i}`;
      const address = `${name}.${ordererOrgDomainJson}`;
      const port = headOrdererPort + i;
      return {
        name,
        domain: ordererOrgDomainJson,
        address,
        consensus,
        port,
        fullAddress: `${address}:${port}`,
      };
    });
};

const extendOrdererOrgConfig = (ordererOrgIndex: number, ordererOrgJson: OrdererOrgJson): OrdererOrgConfig => {
  const { caPort, headOrdererPort } = getPortsForOrdererOrg(ordererOrgIndex);

  const { domain, name } = ordererOrgJson.organization;
  const profileName = `${name}Genesis`;
  const mspName = ordererOrgJson.organization.mspName || defaults.organization.mspName(name);
  const consensus = ordererOrgJson.orderer.type === "raft" ? "etcdraft" : ordererOrgJson.orderer.type;

  const orderersExtended = extendOrderersConfig(headOrdererPort, ordererOrgJson.orderer, domain);
  const ordererHead = orderersExtended[0];

  return {
    name,
    mspName,
    domain,
    profileName,
    genesisBlockName: `${profileName}.block`,
    ca: extendCaConfig(ordererOrgJson.ca, ordererOrgJson.organization.name, domain, caPort),
    consensus,
    orderers: orderersExtended,
    ordererHead,
  };
};

const extendOrdererOrgsConfig = (ordererOrgsJson: OrdererOrgJson[]): OrdererOrgConfig[] => {
  return Array(ordererOrgsJson.length)
    .fill(undefined)
    .map((_x, ordererOrgIndex) => extendOrdererOrgConfig(ordererOrgIndex, ordererOrgsJson[ordererOrgIndex]));
};

const extendRootOrgConfig = (rootOrgJsonFormat: RootOrgJson): RootOrgConfig => {
  const { domain, name } = rootOrgJsonFormat.organization;
  const mspName = rootOrgJsonFormat.organization.mspName || defaults.organization.mspName(name);
  return {
    name,
    mspName,
    domain,
    ca: extendCaConfig(rootOrgJsonFormat.ca, rootOrgJsonFormat.organization.name, domain, 7010),
  };
};

const extendPeers = (
  peerJson: PeerJson,
  domainJsonFormat: string,
  headPeerPort: number,
  headPeerCouchDbExposePort: number,
): PeerConfig[] => {
  const peerPrefix = peerJson.prefix || defaults.peer.prefix;
  const db = peerJson.db || defaults.peer.db;
  const anchorPeerInstances = peerJson.anchorPeerInstances || defaults.peer.anchorPeerInstances(peerJson.instances);

  return Array(peerJson.instances)
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

interface AnchorPeerConfig extends PeerConfig {
  isAnchorPeer: true;
  orgDomain: string;
}

const fabloRestLoggingConfig = (network: NetworkSettings): FabloRestLoggingConfig => {
  const console = "console";
  if (network.monitoring.loglevel.toLowerCase() === "error") return { error: console };
  if (network.monitoring.loglevel.toLowerCase() === "warn") return { error: console, warn: console };
  if (network.monitoring.loglevel.toLowerCase() === "info") return { error: console, warn: console, info: console };
  return { error: console, warn: console, info: console, debug: console };
};

const fabloRestConfig = (
  domain: string,
  mspName: string,
  port: number,
  ca: CAConfig,
  anchorPeersAllOrgs: AnchorPeerConfig[],
  networkSettings: NetworkSettings,
): FabloRestConfig => {
  const discoveryEndpointsConfig = networkSettings.tls
    ? {
        discoveryUrls: anchorPeersAllOrgs.map((p) => `grpcs://${p.address}:${p.port}`).join(","),
        discoverySslTargetNameOverrides: "",
        discoveryTlsCaCertFiles: anchorPeersAllOrgs
          .map((p) => `/crypto/${p.orgDomain}/peers/${p.address}/tls/ca.crt`)
          .join(","),
      }
    : {
        discoveryUrls: anchorPeersAllOrgs.map((p) => `grpc://${p.address}:${p.port}`).join(","),
        discoverySslTargetNameOverrides: "",
        discoveryTlsCaCertFiles: "",
      };

  return {
    address: `fablo-rest.${domain}`,
    mspId: mspName,
    port,
    fabricCaUrl: `http://${ca.address}:${ca.port}`,
    fabricCaName: ca.address,
    ...discoveryEndpointsConfig,
    logging: fabloRestLoggingConfig(networkSettings),
  };
};

const extendOrgConfig = (
  orgJsonFormat: OrgJson,
  caExposePort: number,
  fabloRestPort: number,
  peers: PeerConfig[],
  anchorPeersAllOrgs: AnchorPeerConfig[],
  networkSettings: NetworkSettings,
): OrgConfig => {
  const cryptoConfigFileName = `crypto-config-${orgJsonFormat.organization.name.toLowerCase()}`;
  const { domain, name } = orgJsonFormat.organization;
  const ca = extendCaConfig(orgJsonFormat.ca, name, domain, caExposePort);
  const mspName = orgJsonFormat.organization.mspName || defaults.organization.mspName(name);
  const anchorPeers = peers.filter((p) => p.isAnchorPeer);
  const bootstrapPeersList = anchorPeers.map((a) => a.fullAddress);
  const bootstrapPeersStringParam =
    bootstrapPeersList.length === 1
      ? bootstrapPeersList[0] // note no quotes in parameter
      : `"${bootstrapPeersList.join(" ")}"`;

  const fabloRest: FabloRestConfig | undefined = !orgJsonFormat?.tools?.fabloRest
    ? undefined
    : fabloRestConfig(domain, mspName, fabloRestPort, ca, anchorPeersAllOrgs, networkSettings);

  return {
    name,
    mspName,
    domain,
    cryptoConfigFileName,
    peersCount: peers.length,
    peers,
    anchorPeers,
    bootstrapPeers: bootstrapPeersStringParam,
    ca,
    cli: {
      address: `cli.${orgJsonFormat.organization.domain}`,
    },
    headPeer: peers[0],
    tools: { fabloRest },
  };
};

const getPortsForOrg = (orgIndex: number) => ({
  caPort: 7070 + 10 * orgIndex,
  headPeerPort: 7071 + 10 * orgIndex,
  headPeerCouchDbPort: 5080 + 10 * orgIndex,
  fabloRestPort: 8800 + orgIndex,
});

const extendOrgsConfig = (orgsJsonConfigFormat: OrgJson[], networkSettings: NetworkSettings): OrgConfig[] => {
  const peersByOrgDomain = orgsJsonConfigFormat.reduce((all, orgJson, orgIndex) => {
    const domain = orgJson.organization.domain;
    const { headPeerPort, headPeerCouchDbPort, caPort, fabloRestPort } = getPortsForOrg(orgIndex);
    const peers = extendPeers(orgJson.peer, domain, headPeerPort, headPeerCouchDbPort);
    return { ...all, [domain]: { peers, caPort, fabloRestPort } };
  }, {} as Record<string, { peers: PeerConfig[]; caPort: number; fabloRestPort: number }>);

  const anchorPeers = orgsJsonConfigFormat.reduce((peers, org) => {
    const newAnchorPeers: AnchorPeerConfig[] = peersByOrgDomain[org.organization.domain].peers
      .filter((p) => p.isAnchorPeer)
      .map((p) => ({ ...p, isAnchorPeer: true, orgDomain: org.organization.domain }));
    return peers.concat(newAnchorPeers);
  }, [] as AnchorPeerConfig[]);

  return orgsJsonConfigFormat.map((org) => {
    const { peers, caPort, fabloRestPort } = peersByOrgDomain[org.organization.domain];
    return extendOrgConfig(org, caPort, fabloRestPort, peers, anchorPeers, networkSettings);
  });
};

export { extendRootOrgConfig, extendOrdererOrgsConfig, extendOrgsConfig };
