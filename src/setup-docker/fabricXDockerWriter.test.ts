import { BASE_QUERY_SERVICE_PORT, BASE_SIDECAR_PORT, getFabricXTemplateModel } from "./fabricXDockerWriter";
import {
  CAConfig,
  ChannelConfig,
  CLIConfig,
  FabloConfigExtended,
  FabricXGlobal,
  OrdererConfig,
  OrdererGroup,
  OrgConfig,
} from "../types/FabloConfigExtended";

const createTestOrg = (name: string, domain: string, mspName: string): OrgConfig => {
  const ca: CAConfig = {
    address: `ca.${domain}`,
    caAdminNameVar: "ADMIN_NAME",
    caAdminPassVar: "ADMIN_PASS",
    exposePort: 7054,
    fullAddress: `ca.${domain}:7054`,
    port: 7054,
    prefix: "ca",
    db: "sqlite",
  };

  const cli: CLIConfig = {
    address: `cli.${domain}`,
  };

  return {
    name,
    domain,
    mspName,
    anchorPeers: [],
    bootstrapPeers: "",
    ca,
    cli,
    cryptoConfigFileName: `crypto-config-${name.toLowerCase()}.yaml`,
    peers: [],
    peersCount: 0,
    ordererGroups: [],
    tools: {},
  };
};

const createTestChannel = (name: string, profileName: string, orgs: OrgConfig[]): ChannelConfig => {
  const dummyOrderer: OrdererConfig = {
    name: "orderer1",
    domain: "orderer.example.com",
    address: "orderer1.orderer.example.com",
    adminPort: 7050,
    port: 7050,
    fullAddress: "orderer1.orderer.example.com:7050",
    orgName: "OrdererOrg",
    orgMspName: "OrdererMSP",
  };

  const dummyOrdererGroup: OrdererGroup = {
    name: "OrdererGroup",
    consensus: "solo",
    profileName: "OrdererProfile",
    genesisBlockName: "genesis.block",
    configtxOrdererDefaults: "OrdererDefaults",
    hostingOrgs: ["OrdererOrg"],
    orderers: [dummyOrderer],
    ordererHeads: [dummyOrderer],
  };

  return {
    name,
    profileName,
    ordererGroup: dummyOrdererGroup,
    ordererHead: dummyOrderer,
    orgs,
    instantiatingOrg: orgs[0],
  };
};

const createTestGlobal = (): FabricXGlobal => ({
  provider: "fabric-x",
  fabricVersion: "2.5.0",
  ordererVersion: "0.2.0",
  committerVersion: "0.2.0",
  toolsVersion: "0.2.0",
  postgresVersion: "18.4",
  ordererImage: "hyperledger/fabric-x-orderer:0.2.0",
  toolsImage: "hyperledger/fabric-x-tools:0.2.0",
  committerImage: "hyperledger/fabric-x-committer:0.2.0",
  postgresImage: "postgres:18.4",
  tls: false,
  engine: "docker",
  monitoring: { loglevel: "info" },
  paths: { fabloConfig: "fablo-config.json", chaincodesBaseDir: "chaincodes" },
  capabilities: {
    application: "V2_5",
    channel: "V2_0",
    orderer: "V2_0",
    isV2: true,
    isV3: false,
  },
  tools: {},
});

const createTestConfig = (channels: ChannelConfig[], orgs: OrgConfig[] = []): FabloConfigExtended => ({
  global: createTestGlobal(),
  ordererGroups: [],
  orderedHeadsDistinct: [],
  orgs,
  channels,
  chaincodes: [],
  hooks: {
    postGenerate: "",
    postStart: "",
  },
  namespaces: [],
});

describe("fabricXDockerWriter - getFabricXTemplateModel", () => {
  it("resolves multi-org topology with named port offsets and combined policy", () => {
    const org1 = createTestOrg("Org1", "org1.com", "Org1MSP");
    const org2 = createTestOrg("Org2", "org2.com", "Org2MSP");
    const channel = createTestChannel("my-channel", "MyChannel", [org1, org2]);
    const configExtended = createTestConfig([channel], [org1, org2]);

    const model = getFabricXTemplateModel(configExtended);

    expect(model.channelName).toBe("my-channel");
    expect(model.channelProfileName).toBe("MyChannel");
    expect(model.applicationOrgs).toHaveLength(2);

    expect(model.applicationOrgs[0].name).toBe("Org1");
    expect(model.applicationOrgs[0].slug).toBe("org1");
    expect(model.applicationOrgs[0].sidecarPort).toBe(BASE_SIDECAR_PORT);
    expect(model.applicationOrgs[0].queryServicePort).toBe(BASE_QUERY_SERVICE_PORT);

    expect(model.applicationOrgs[1].name).toBe("Org2");
    expect(model.applicationOrgs[1].slug).toBe("org2");
    expect(model.applicationOrgs[1].sidecarPort).toBe(BASE_SIDECAR_PORT + 1);
    expect(model.applicationOrgs[1].queryServicePort).toBe(BASE_QUERY_SERVICE_PORT + 1);

    expect(model.defaultPolicy).toBe("AND('Org1MSP.member','Org2MSP.member')");
  });

  it("throws when channels is empty", () => {
    const config = createTestConfig([]);
    expect(() => getFabricXTemplateModel(config)).toThrow("Fabric-X generation requires exactly one channel.");
  });

  it("throws when multiple channels are configured", () => {
    const org1 = createTestOrg("Org1", "org1.com", "Org1MSP");
    const ch1 = createTestChannel("ch1", "Profile1", [org1]);
    const ch2 = createTestChannel("ch2", "Profile2", [org1]);
    const config = createTestConfig([ch1, ch2], [org1]);
    expect(() => getFabricXTemplateModel(config)).toThrow("Fabric-X generation requires exactly one channel.");
  });

  it("throws when channel has no organizations", () => {
    const channel = createTestChannel("my-channel", "MyChannel", []);
    const config = createTestConfig([channel]);
    expect(() => getFabricXTemplateModel(config)).toThrow(
      "Fabric-X generator requires at least one channel with an organization.",
    );
  });
});
