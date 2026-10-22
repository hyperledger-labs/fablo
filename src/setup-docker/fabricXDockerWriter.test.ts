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

  it("refuses to generate more than one party", () => {
    const writer = new FabricXDockerWriter(path.join(__dirname, "templates"), outputDir, () => undefined);
    return expect(writer.write(extendConfig(fabricXConfig(4)))).rejects.toThrow(/supports 1 party/);
  });
});
