export interface NetworkSettingsJson {
  fabricVersion: string;
  tls: boolean;
  monitoring?: { loglevel: string };
}

export interface OrganizationDetailsJson {
  name: string;
  mspName: string;
  domain: string;
}

export interface CAJson {
  prefix: string;
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
  peer: PeerJson | undefined;
  tools?: { fabloRest?: boolean };
}

export interface ChannelJson {
  name: string;
  ordererGroup: string | undefined;
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

export interface FabloConfigJson {
  $schema: string;
  networkSettings: NetworkSettingsJson;
  orgs: OrgJson[];
  channels: ChannelJson[];
  chaincodes: ChaincodeJson[];
}
