export interface FabricVersions {
  fabricVersion: string;
  fabricCaVersion: string;
  fabricCcenvVersion: string;
  fabricBaseosVersion: string;
  fabricJavaenvVersion: string;
  fabricNodeenvVersion: string;
  fabricRecommendedNodeVersion: string;
}

interface CapabilitiesV1 {
  application: "V1_3" | "V1_4_2";
  channel: "V1_3" | "V1_4_2" | "V1_4_3";
  orderer: "V1_1" | "V1_4_2";
  isV2: false;
}

interface CapabilitiesV2 {
  application: "V2_0";
  channel: "V2_0";
  orderer: "V2_0";
  isV2: true;
}

export type Capabilities = CapabilitiesV1 | CapabilitiesV2;

export interface Global extends FabricVersions {
  tls: boolean;
  engine: "kubernetes" | "docker"
  monitoring: { loglevel: string };
  paths: { fabloConfig: string; chaincodesBaseDir: string };
  capabilities: Capabilities;
  tools: { explorer?: ExplorerConfig };
}

export interface OrdererConfig {
  name: string;
  domain: string;
  address: string;
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
  db: "sqlite" | "postgres";
}

export interface PeerConfig {
  address: string;
  couchDbExposePort: number;
  db: PeerDbConfig;
  fullAddress: string;
  isAnchorPeer: boolean;
  name: string;
  port: number;
  gatewayEnabled: boolean;
}

export interface PeerDbConfig {
  type: "LevelDb" | "CouchDb";
  image?: string;
}

export interface CLIConfig {
  address: string;
}

export interface ChannelConfig {
  name: string;
  profileName: string;
  ordererGroup: OrdererGroup;
  ordererHead: OrdererConfig;
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

export interface FabloRestLoggingConfig {
  info?: "console" | string;
  warn?: "console" | string;
  error?: "console" | string;
  debug?: "console" | string;
}

export interface FabloRestConfig {
  address: string;
  port: number;
  mspId: string;
  fabricCaUrl: string;
  fabricCaName: string;
  discoveryUrls: string;
  discoverySslTargetNameOverrides: string;
  discoveryTlsCaCertFiles: string;
  logging: FabloRestLoggingConfig;
}

export interface ExplorerConfig {
  address: string;
  port: number;
}

export interface OrgConfig {
  anchorPeers: PeerConfig[];
  bootstrapPeers: string;
  ca: CAConfig;
  cli: CLIConfig;
  cryptoConfigFileName: string;
  domain: string;
  headPeer?: PeerConfig;
  mspName: string;
  name: string;
  peers: PeerConfig[];
  peersCount: number;
  ordererGroups: OrdererGroup[];
  tools: { fabloRest?: FabloRestConfig; explorer?: ExplorerConfig };
}

export interface ChaincodeConfig {
  directory: string;
  name: string;
  version: string;
  lang: string;
  channel: ChannelConfig;
  init?: string;
  initRequired?: boolean;
  endorsement?: string;
  instantiatingOrg: OrgConfig;
  privateDataConfigFile?: string;
  privateData: PrivateCollectionConfig[];
}

export interface OrdererGroup {
  name: string;
  consensus: "solo" | "etcdraft";
  profileName: string;
  genesisBlockName: string;
  configtxOrdererDefaults: string;
  hostingOrgs: string[];
  orderers: OrdererConfig[];
  ordererHeads: OrdererConfig[];
}

export interface HooksConfig {
  postGenerate: string;
}

export interface FabloConfigExtended {
  global: Global;
  ordererGroups: OrdererGroup[];
  orderedHeadsDistinct: OrdererConfig[];
  orgs: OrgConfig[];
  channels: ChannelConfig[];
  chaincodes: ChaincodeConfig[];
  hooks: HooksConfig;
}
