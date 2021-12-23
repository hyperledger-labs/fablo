import defaults from "./defaults";
import { CAJson, OrdererJson, OrgJson, PeerJson } from "../types/FabloConfigJson";
import {
  CAConfig,
  FabloRestConfig,
  FabloRestLoggingConfig,
  ExplorerConfig,
  Global,
  OrdererConfig,
  OrdererGroup,
  OrgConfig,
  PeerConfig,
  PeerDbConfig,
} from "../types/FabloConfigExtended";
import _ = require("lodash");
import { version } from "../repositoryUtils";

const extendCaConfig = (
  caJsonFormat: CAJson,
  orgName: string,
  orgDomainJsonFormat: string,
  caExposePort: number,
): CAConfig => {
  const caPrefix = caJsonFormat?.prefix || defaults.ca.prefix;
  const caDb = caJsonFormat?.db || defaults.ca.db;
  const address = `${caPrefix}.${orgDomainJsonFormat}`;
  const port = 7054;
  return {
    prefix: caPrefix,
    address,
    port,
    exposePort: caExposePort,
    fullAddress: `${address}:${port}`,
    caAdminNameVar: `${orgName.toUpperCase()}_CA_ADMIN_NAME`,
    caAdminPassVar: `${orgName.toUpperCase()}_CA_ADMIN_PASSWORD`,
    db: caDb,
  };
};

const extendOrderersConfig = (
  headOrdererPort: number,
  groupName: string,
  ordererJson: OrdererJson,
  ordererOrgDomainJson: string,
): OrdererConfig[] => {
  const consensus = ordererJson.type === "raft" ? "etcdraft" : ordererJson.type;
  const prefix = ordererJson.prefix ?? defaults.orderer.prefix;

  return Array(ordererJson.instances)
    .fill(undefined)
    .map((_x, i) => {
      const name = `${prefix}${i}.${groupName}`;
      const address = `${name}.${ordererOrgDomainJson}`;
      const port = headOrdererPort + i;
      return {
        name,
        address,
        domain: ordererOrgDomainJson,
        consensus,
        port,
        fullAddress: `${address}:${port}`,
      };
    });
};

const portsForOrdererGroups = (headOrdererPort: number, orderersJson: OrdererJson[]) => {
  const instancesArray = orderersJson
    .map((o) => o.instances)
    .reduce((arr, n) => [...arr, arr.length === 0 ? n : arr[arr.length - 1] + n], [] as number[]);
  return instancesArray.map((_instance, index) => {
    const port = index == 0 ? headOrdererPort : instancesArray[index - 1] + headOrdererPort;
    return port;
  });
};

const extendOrderersGroupForOrg = (
  headOrdererPort: number,
  orgName: string,
  orderersJson: OrdererJson[],
  ordererOrgDomainJson: string,
): OrdererGroup[] => {
  const portsArray = portsForOrdererGroups(headOrdererPort, orderersJson);

  return orderersJson.map((ordererJson, i) => {
    const groupName = ordererJson.groupName;
    const consensus = ordererJson.type === "raft" ? "etcdraft" : ordererJson.type;
    const orderers = extendOrderersConfig(portsArray[i], groupName, ordererJson, ordererOrgDomainJson);

    const profileName = _.upperFirst(`${groupName}Genesis`);
    const genesisBlockName = `${profileName}.block`;
    const configtxOrdererDefaults = _.upperFirst(`${groupName}Defaults`);

    return {
      name: groupName,
      consensus,
      configtxOrdererDefaults,
      profileName,
      genesisBlockName,
      hostingOrgs: [orgName],
      orderers,
      ordererHeads: [orderers[0]],
    };
  });
};

const extendPeers = (
  fabricVersion: string,
  peerJson: PeerJson,
  domainJsonFormat: string,
  headPeerPort: number,
  headPeerCouchDbExposePort: number,
): PeerConfig[] => {
  const peerPrefix = peerJson.prefix || defaults.peer.prefix;
  const anchorPeerInstances = peerJson.anchorPeerInstances || defaults.peer.anchorPeerInstances(peerJson.instances);

  const dbType = peerJson.db || defaults.peer.db;
  const db: PeerDbConfig = { type: dbType };
  if (dbType === "CouchDb") {
    if (version(fabricVersion).isGreaterOrEqual("2.2")) {
      db["image"] = "couchdb:${COUCHDB_VERSION}";
    } else {
      db["image"] = "hyperledger/fabric-couchdb:${FABRIC_COUCHDB_VERSION}";
    }
  }

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

const fabloRestLoggingConfig = (network: Global): FabloRestLoggingConfig => {
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
  global: Global,
): FabloRestConfig => {
  const discoveryEndpointsConfig = global.tls
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
    logging: fabloRestLoggingConfig(global),
  };
};

const explorerConfig = (domain: string, port: number): ExplorerConfig => {
  return {
    address: `explorer.${domain}`,
    port,
  };
};

const extendOrgConfig = (
  orgJsonFormat: OrgJson,
  caExposePort: number,
  ordererHeadExposePort: number,
  fabloRestPort: number,
  explorerPort: number,
  peers: PeerConfig[],
  anchorPeersAllOrgs: AnchorPeerConfig[],
  global: Global,
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

  const fabloRest = !orgJsonFormat?.tools?.fabloRest
    ? {}
    : { fabloRest: fabloRestConfig(domain, mspName, fabloRestPort, ca, anchorPeersAllOrgs, global) };

  const explorer = !orgJsonFormat?.tools?.explorer ? {} : { explorer: explorerConfig(domain, explorerPort) };

  const ordererGroups =
    orgJsonFormat.orderers !== undefined
      ? extendOrderersGroupForOrg(ordererHeadExposePort, name, orgJsonFormat.orderers, domain)
      : [];

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
    ordererGroups,
    tools: { ...fabloRest, ...explorer },
  };
};

const getPortsForOrg = (orgIndex: number) => ({
  caPort: 7020 + 20 * orgIndex,
  headPeerPort: 7021 + 20 * orgIndex,
  headOrdererPort: 7030 + 20 * orgIndex,
  headPeerCouchDbPort: 5080 + 20 * orgIndex,
  fabloRestPort: 8800 + orgIndex,
  explorerPort: 7010 + orgIndex,
});

const extendOrgsConfig = (orgsJsonConfigFormat: OrgJson[], global: Global): OrgConfig[] => {
  const peersByOrgDomain = orgsJsonConfigFormat.reduce((all, orgJson, orgIndex) => {
    const domain = orgJson.organization.domain;
    const { caPort, headPeerPort, headPeerCouchDbPort, fabloRestPort, explorerPort } = getPortsForOrg(orgIndex);
    const peers =
      orgJson.peer !== undefined
        ? extendPeers(global.fabricVersion, orgJson.peer, domain, headPeerPort, headPeerCouchDbPort)
        : [];
    return { ...all, [domain]: { peers, caPort, fabloRestPort, explorerPort } };
  }, {} as Record<string, { peers: PeerConfig[]; caPort: number; fabloRestPort: number; explorerPort: number }>);

  const anchorPeers = orgsJsonConfigFormat.reduce((peers, org) => {
    const newAnchorPeers: AnchorPeerConfig[] = peersByOrgDomain[org.organization.domain].peers
      .filter((p) => p.isAnchorPeer)
      .map((p) => ({ ...p, isAnchorPeer: true, orgDomain: org.organization.domain }));
    return peers.concat(newAnchorPeers);
  }, [] as AnchorPeerConfig[]);

  return orgsJsonConfigFormat.map((org, orgIndex) => {
    const { headOrdererPort } = getPortsForOrg(orgIndex);
    const { peers, caPort, fabloRestPort, explorerPort } = peersByOrgDomain[org.organization.domain];
    return extendOrgConfig(org, caPort, headOrdererPort, fabloRestPort, explorerPort, peers, anchorPeers, global);
  });
};

export { extendOrgsConfig };
