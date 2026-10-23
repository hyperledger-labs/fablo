import * as fs from "fs-extra";
import * as os from "os";
import * as path from "path";
import extendConfig from "../extend-config/extendConfig";
import { FabloConfigJson } from "../types/FabloConfigJson";
import { FabricXDockerWriter } from "./fabricXDockerWriter";

const fabricXConfig = (instances: number): FabloConfigJson => ({
  $schema: "https://github.com/hyperledger-labs/fablo/releases/download/2.6.0/schema.json",
  global: { fabricVersion: "3.1.0", tls: true, engine: "docker", peerDevMode: false, provider: "fabric-x" },
  orgs: [
    {
      organization: { name: "Org1", domain: "org1.example.com", mspName: "Org1MSP" },
      ca: { prefix: "ca", db: "sqlite" },
      orderers: [{ groupName: "group1", type: "BFT", instances, prefix: "orderer" }],
    },
  ],
  channels: [{ name: "mychannel", orgs: [{ name: "Org1", peers: [] }] }],
  namespaces: [{ name: "mynamespace", orgs: ["Org1"] }],
  chaincodes: [],
  hooks: {},
});

describe("FabricXDockerWriter orderer topology", () => {
  let outputDir: string;

  beforeAll(async () => {
    outputDir = await fs.mkdtemp(path.join(os.tmpdir(), "fablo-fabric-x-"));
    const writer = new FabricXDockerWriter(path.join(__dirname, "templates"), outputDir, () => undefined);
    await writer.write(extendConfig(fabricXConfig(1)));
  });

  afterAll(async () => {
    await fs.remove(outputDir);
  });

  const read = (file: string): Promise<string> => fs.readFile(path.join(outputDir, "fabric-x", file), "utf-8");

  it("writes one config file per orderer node", async () => {
    const files = await fs.readdir(path.join(outputDir, "fabric-x", "config"));
    expect(files).toEqual(
      expect.arrayContaining([
        "party1-router.yaml",
        "party1-batcher.yaml",
        "party1-consenter.yaml",
        "party1-assembler.yaml",
      ]),
    );
  });

  it("takes party id, port and MSP of a node config from the model", async () => {
    const router = await read("config/party1-router.yaml");
    expect(router).toContain("PartyID: 1");
    expect(router).toContain("ListenPort: 7050");
    expect(router).toContain("LocalMSPID: OrdererOrdererMSP");
    expect(await read("config/party1-batcher.yaml")).toContain("ShardID: 1");
  });

  it("renders the orderer services in docker-compose", async () => {
    const compose = await read("docker-compose.yaml");
    expect(compose).toContain("container_name: orderer-consenter");
    expect(compose).toContain("command: consensus --config=/config/node_config.yaml");
    expect(compose).toContain("./data/orderers/party1-assembler:/data:Z");
  });

  it("lists the party in the shared config and configtx", async () => {
    expect(await read("shared-config.yaml")).toContain("MaxPartyID: 1");
    expect(await read("configtx.yaml")).toContain("id=0,broadcast,orderer-router:7050");
  });

  it("refuses party counts that are not supported", () => {
    const writer = new FabricXDockerWriter(path.join(__dirname, "templates"), outputDir, () => undefined);
    return expect(writer.write(extendConfig(fabricXConfig(2)))).rejects.toThrow(/supports 1 or 4 parties/);
  });
});

describe("FabricXDockerWriter four party profile", () => {
  let outputDir: string;

  beforeAll(async () => {
    outputDir = await fs.mkdtemp(path.join(os.tmpdir(), "fablo-fabric-x-4-"));
    const writer = new FabricXDockerWriter(path.join(__dirname, "templates"), outputDir, () => undefined);
    await writer.write(extendConfig(fabricXConfig(4)));
  });

  afterAll(async () => {
    await fs.remove(outputDir);
  });

  const read = (file: string): Promise<string> => fs.readFile(path.join(outputDir, "fabric-x", file), "utf-8");

  it("writes a config file for each of the 16 orderer nodes", async () => {
    const files = (await fs.readdir(path.join(outputDir, "fabric-x", "config"))).filter((f) => f.startsWith("party"));
    expect(files).toHaveLength(16);
    expect(files).toContain("party4-assembler.yaml");
  });

  it("gives each node its own party id, port and MSP", async () => {
    const config = await read("config/party3-consenter.yaml");
    expect(config).toContain("PartyID: 3");
    expect(config).toContain("ListenPort: 7252");
    expect(config).toContain("LocalMSPID: OrdererOrg3MSP");
  });

  it("creates one orderer org per party in crypto-config and configtx", async () => {
    const crypto = await read("crypto-config.yaml");
    const configtx = await read("configtx.yaml");
    [1, 2, 3, 4].forEach((n) => {
      expect(crypto).toContain(`Domain: orderer-org-${n}`);
      expect(configtx).toContain(`- &OrdererOrg${n}MSP`);
      expect(configtx).toContain(`- *OrdererOrg${n}MSP`);
      expect(configtx).toContain(`id=${n - 1},broadcast,orderer-party${n}-router:7${n - 1}50`);
    });
    expect(configtx.match(/^ {4}- ID: \d$/gm)).toHaveLength(4);
  });

  it("lists all four parties in the shared config", async () => {
    const shared = await read("shared-config.yaml");
    expect(shared).toContain("MaxPartyID: 4");
    expect(shared.match(/- PartyID: \d/g)).toHaveLength(4);
  });

  it("makes batchers wait for every consenter and the sidecar for every router", async () => {
    const compose = await read("docker-compose.yaml");
    const batcher = compose.slice(
      compose.indexOf("\n  orderer-party2-batcher:\n"),
      compose.indexOf("\n  orderer-party2-consenter:\n"),
    );
    [1, 2, 3, 4].forEach((n) => expect(batcher).toContain(`      orderer-party${n}-consenter:`));
    const sidecar = compose.slice(compose.indexOf("\n  committer-org1-sidecar:\n"));
    [1, 2, 3, 4].forEach((n) => expect(sidecar).toContain(`      orderer-party${n}-router:`));
  });

  it("switches the sidecar to BFT and trusts every orderer org", async () => {
    const sidecar = await read("config/sidecar.yaml");
    expect(sidecar).toContain("fault-tolerance-level: BFT");
    [1, 2, 3, 4].forEach((n) => expect(sidecar).toContain(`/orderer-cas/orderer-org-${n}/msp/tlscacerts/`));
  });

  it("points fxconfig at the router of party 1", async () => {
    expect(await read("fxconfig.yaml")).toContain("address: orderer-party1-router:7050");
  });
});
