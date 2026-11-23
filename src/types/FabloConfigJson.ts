export interface GlobalJson {
  fabricVersion: string;
  tls: boolean;
  peerDevMode: boolean;
  fabricImages?: FabricImagesJson;
  engine?: "kubernetes" | "docker";
  provider?: "fabric" | "fabric-x";
  monitoring?: { loglevel: string };
  tools?: { explorer?: boolean };
}

export interface FabricImagesJson {
  peer?: string;
  orderer?: string;
  ca?: string;
  tools?: string;
  ccenv?: string;
  baseos?: string;
  javaenv?: string;
  nodeenv?: string;
  committer?: string;
  postgres?: string;
}

export interface OrganizationDetailsJson {
  name: string;
  mspName: string;
  domain: string;
}

export interface CAJson {
  prefix: string;
  db: "sqlite" | "postgres" | "mysql";
}

export interface OrdererJson {
  groupName: string;
  prefix: string;
  type: "solo" | "raft" | "BFT";
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
  orderers?: OrdererJson[];
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
  lang: "node" | "java" | "golang" | "ccaas";
  channel: string;
  init?: string;
  initRequired?: boolean;
  endorsement?: string;
  directory?: string;
  image?: string;
  port?: number;
  chaincodeMountPath?: string;
  chaincodeStartCommand?: string;
  privateData: PrivateDataJson[];
}

export interface HooksJson {
  postGenerate?: string;
  postStart?: string;
}
export interface NamespaceJson {
  name: string;
  orgs?: string[];
  policy?: string;
}
export interface FabricXJson {
  orderer?: { partyCount?: number };
}
export interface FabloConfigJson {
  $schema: string;
  global: GlobalJson;
  orgs: OrgJson[];
  channels: ChannelJson[];
  chaincodes: ChaincodeJson[];
  hooks: HooksJson;
  namespaces?: NamespaceJson[];
  fabricX?: FabricXJson;
}


export interface FabricXOrgJson extends Omit<OrgJson, "organization" | "ca"> {
  organization: Omit<OrganizationDetailsJson, "mspName"> & { mspName?: string };
  ca?: CAJson;
}
export interface FabricXChannelJson {
  name: string;
  orgs?: { name: string; peers?: string[] }[];
}
export interface FabricXConfigJson
  extends Omit<FabloConfigJson, "global" | "orgs" | "channels" | "chaincodes" | "hooks"> {
  global: Omit<GlobalJson, "provider" | "fabricVersion" | "tls" | "peerDevMode"> &
    Partial<Pick<GlobalJson, "fabricVersion" | "tls" | "peerDevMode">> & { provider: "fabric-x" };
  orgs: FabricXOrgJson[];
  channels: FabricXChannelJson[];
  chaincodes?: ChaincodeJson[];
  hooks?: HooksJson;
}
