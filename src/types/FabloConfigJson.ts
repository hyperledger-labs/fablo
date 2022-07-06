export interface GlobalJson {
  fabricVersion: string;
  tls: boolean;
  peerDevMode: boolean;
  monitoring?: { loglevel: string };
  tools?: { explorer?: boolean };
}

export interface OrganizationDetailsJson {
  name: string;
  mspName: string;
  domain: string;
}

export interface CAJson {
  prefix: string;
  db: "sqlite" | "postgres";
}

export interface OrdererJson {
  groupName: string;
  prefix: string;
  type: "solo" | "raft";
  instances: number;
}

export interface PeerJson {
  prefix: string;
  instances: number;
  db: "LevelDb" | "CouchDb";
  anchorPeerInstances?: number;
}

export interface OrgJson {
  organization: OrganizationDetailsJson;
  ca: CAJson;
  orderers: OrdererJson[] | undefined;
  peer?: PeerJson;
  tools?: { fabloRest?: boolean; explorer?: boolean };
}

export interface ChannelJson {
  name: string;
  ordererGroup?: string;
  orgs: { name: string; peers: string[] }[];
}

export interface PrivateDataJson {
  name: string;
  orgNames: string[];
}

export interface ChaincodeJson {
  name: string;
  version: string;
  lang: "node" | "java" | "golang";
  channel: string;
  init?: string;
  initRequired?: boolean;
  endorsement?: string;
  directory: string;
  privateData: PrivateDataJson[];
}

export interface HooksJson {
  postGenerate?: string;
}

export interface FabloConfigJson {
  $schema: string;
  global: GlobalJson;
  orgs: OrgJson[];
  channels: ChannelJson[];
  chaincodes: ChaincodeJson[];
  hooks: HooksJson;
}
