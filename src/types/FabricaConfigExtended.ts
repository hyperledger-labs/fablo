export interface NetworkSettings {
  fabricVersion: string;
  fabricCaVersion: string;
  tls: boolean;
  monitoring: { loglevel: string };
  paths: { fabricaConfig: string; chaincodesBaseDir: string };
}

export interface Capabilities {
  application: "V1_3" | "V1_4_2" | "V2_0";
  channel: "V1_3" | "V1_4_2" | "V1_4_3" | "V2_0";
  orderer: "V1_1" | "V1_4_2" | "V2_0";
}

export interface OrdererConfig {
  name: string;
  domain: string;
  address: string;
  consensus: "solo" | "etcdraft";
  port: number;
  fullAddress: string;
}

export interface CAConfig {
  address: string;
  caAdminNameVar: string;
  caAdminPassVar: string;
  exposePort: number;
  fullAddress: string;
  port: number;
  prefix: string;
}

export interface PeerConfig {
  address: string;
  couchDbExposePort: number;
  db: "LevelDb" | "CouchDb";
  fullAddress: string;
  isAnchorPeer: boolean;
  name: string;
  port: number;
}

export interface CLIConfig {
  address: string;
}

export interface ChannelConfig {
  name: string;
  orgs: OrgConfig[];
  instantiatingOrg: OrgConfig;
}

export interface PrivateCollectionConfig {
  name: string;
  policy: string;
  requiredPeerCount: number;
  maxPeerCount: number;
  blockToLive: number;
  memberOnlyRead?: boolean;
  memberOnlyWrite?: boolean;
}

export interface RootOrgConfig {
  name: string;
  mspName: string;
  domain: string;
  ca: CAConfig;
  orderers: OrdererConfig[];
  ordererHead: OrdererConfig;
}

export interface OrgConfig {
  anchorPeers: PeerConfig[];
  bootstrapPeers: string;
  ca: CAConfig;
  cli: CLIConfig;
  cryptoConfigFileName: string;
  domain: string;
  headPeer: PeerConfig;
  mspName: string;
  name: string;
  peers: PeerConfig[];
  peersCount: number;
}

export interface ChaincodeConfig {
  directory: string;
  name: string;
  version: string;
  lang: string;
  channel: ChannelConfig;
  init: string;
  endorsement: string;
  instantiatingOrg: OrgConfig;
  privateDataConfigFile?: string;
  privateData: PrivateCollectionConfig[];
}

export interface FabricaConfigExtended {
  networkSettings: NetworkSettings;
  capabilities: Capabilities;
  rootOrg: RootOrgConfig;
  orgs: OrgConfig[];
  channels: ChannelConfig[];
  chaincodes: ChaincodeConfig[];
}
