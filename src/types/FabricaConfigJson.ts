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

export interface RootOrgJson {
  organization: OrganizationDetailsJson;
  ca: CAJson;
}

export interface OrgJson {
  organization: OrganizationDetailsJson;
  ca: CAJson;
  peer: PeerJson;
  tools?: { fabloRest?: boolean };
}

export interface ChannelJson {
  name: string;
  ordererOrg: string;
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

export interface OrdererOrgJson {
  organization: OrganizationDetailsJson;
  ca: CAJson;
  orderer: OrdererJson;
}

export interface FabloConfigJson {
  $schema: string;
  networkSettings: NetworkSettingsJson;
  rootOrg: RootOrgJson;
  ordererOrgs: OrdererOrgJson[];
  orgs: OrgJson[];
  channels: ChannelJson[];
  chaincodes: ChaincodeJson[];
}
