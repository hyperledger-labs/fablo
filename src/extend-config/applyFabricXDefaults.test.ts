import applyFabricXDefaults from "./applyFabricXDefaults";
import { FabloConfigJson, FabricXConfigJson } from "../types/FabloConfigJson";

const fabricXConfig = (): FabricXConfigJson => ({
  $schema: "https://github.com/hyperledger-labs/fablo/releases/download/2.6.0/schema.json",
  global: { provider: "fabric-x" },
  orgs: [
    { organization: { name: "Org1", domain: "org1.example.com" } },
    { organization: { name: "Org2", domain: "org2.example.com" } },
  ],
  channels: [{ name: "mychannel" }],
  namespaces: [{ name: "mynamespace" }],
});

describe("applyFabricXDefaults", () => {
  it("should fill in the omitted values for fabric-x", () => {
   
    const result = applyFabricXDefaults(fabricXConfig());

    expect(result.global).toEqual({ provider: "fabric-x", fabricVersion: "3.1.0", tls: true, peerDevMode: false });
    expect(result.orgs.map((org) => org.organization.mspName)).toEqual(["Org1MSP", "Org2MSP"]);
    expect(result.orgs.map((org) => org.ca)).toEqual([
      { prefix: "ca", db: "sqlite" },
      { prefix: "ca", db: "sqlite" },
    ]);
    expect(result.channels).toEqual([
      {
        name: "mychannel",
        orgs: [
          { name: "Org1", peers: [] },
          { name: "Org2", peers: [] },
        ],
      },
    ]);
    expect(result.chaincodes).toEqual([]);
    expect(result.hooks).toEqual({});
  });

  it("should keep the values given explicitly", () => {

    const config = fabricXConfig();
    config.global.fabricVersion = "3.0.0";
    config.global.tls = false;
    config.orgs[0].organization.mspName = "CustomMSP";
    config.orgs[0].ca = { prefix: "custom-ca", db: "postgres" };
    config.channels[0].orgs = [{ name: "Org2" }];

 
    const result = applyFabricXDefaults(config);


    expect(result.global.fabricVersion).toEqual("3.0.0");
    expect(result.global.tls).toEqual(false);
    expect(result.orgs[0].organization.mspName).toEqual("CustomMSP");
    expect(result.orgs[0].ca).toEqual({ prefix: "custom-ca", db: "postgres" });
    expect(result.channels[0].orgs).toEqual([{ name: "Org2", peers: [] }]);
  });

  it("should not change a config of the fabric provider", () => {

    const config = {
      global: { fabricVersion: "3.1.5", tls: true },
      orgs: [],
      channels: [],
    } as unknown as FabloConfigJson;

  
    const result = applyFabricXDefaults(config);

    expect(result).toBe(config);
  });
});
