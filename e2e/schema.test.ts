import { matchers } from "jest-json-schema";
import * as schema from "../docs/schema.json";
import * as docsSample from "../docs/sample.json";
import { FabloConfigJson, PrivateDataJson } from "../src/types/FabloConfigJson";

expect.extend(matchers);

describe("schema", () => {
  const base = docsSample;
  expect(base).toMatchSchema(schema);

  const updatedBase = (updateJson: (_: FabloConfigJson) => void): Record<string, unknown> => {
    const json = JSON.parse(JSON.stringify(base));
    updateJson(json as FabloConfigJson);
    return json;
  };

  const lettersOnly = "lettersonly";
  const underscore = "under_score";
  const lettersAndNumber = "lettersand4";
  const uppercase = "UpperCase";
  const domain = "domain.example.com";
  const spaces = "with spaces";
  const specialCharacters1 = "with!characters";
  const specialCharacters2 = "withspecial@";

  it("should match snapshot", () => {
    expect(schema).toMatchSnapshot();
  });

  it("should validate fabric version", () => {
    const withFabricVersion = (v: string) =>
      updatedBase((json: FabloConfigJson) => {
        json.networkSettings.fabricVersion = v;
      });

    expect(withFabricVersion("1.4.3")).toMatchSchema(schema);
    expect(withFabricVersion("1.4.4")).toMatchSchema(schema);
    expect(withFabricVersion("1.3.1")).not.toMatchSchema(schema);
    expect(withFabricVersion("2.0.0")).not.toMatchSchema(schema);
  });

  it("should validate root org name", () => {
    const withRootOrgName = (n: string) =>
      updatedBase((json: FabloConfigJson) => {
        json.rootOrg.organization.name = n;
      });

    expect(withRootOrgName(lettersOnly)).toMatchSchema(schema);
    expect(withRootOrgName(lettersAndNumber)).toMatchSchema(schema);
    expect(withRootOrgName(uppercase)).toMatchSchema(schema);
    expect(withRootOrgName(domain)).not.toMatchSchema(schema);
    expect(withRootOrgName(spaces)).not.toMatchSchema(schema);
    expect(withRootOrgName(specialCharacters1)).not.toMatchSchema(schema);
    expect(withRootOrgName(specialCharacters2)).not.toMatchSchema(schema);
  });

  it("should validate root org MSP name", () => {
    const withRootOrgMSPName = (n: string) =>
      updatedBase((json: FabloConfigJson) => {
        json.rootOrg.organization.mspName = n;
      });

    expect(withRootOrgMSPName(lettersOnly)).toMatchSchema(schema);
    expect(withRootOrgMSPName(lettersAndNumber)).toMatchSchema(schema);
    expect(withRootOrgMSPName(uppercase)).toMatchSchema(schema);
    expect(withRootOrgMSPName(domain)).not.toMatchSchema(schema);
    expect(withRootOrgMSPName(spaces)).not.toMatchSchema(schema);
    expect(withRootOrgMSPName(specialCharacters1)).not.toMatchSchema(schema);
    expect(withRootOrgMSPName(specialCharacters2)).not.toMatchSchema(schema);
  });

  it("should validate root org domain", () => {
    const withRootOrgDomain = (d: string) =>
      updatedBase((json: FabloConfigJson) => {
        json.rootOrg.organization.domain = d;
      });

    expect(withRootOrgDomain(lettersOnly)).toMatchSchema(schema);
    expect(withRootOrgDomain(lettersAndNumber)).toMatchSchema(schema);
    expect(withRootOrgDomain(uppercase)).not.toMatchSchema(schema);
    expect(withRootOrgDomain(domain)).toMatchSchema(schema);
    expect(withRootOrgDomain(spaces)).not.toMatchSchema(schema);
    expect(withRootOrgDomain(specialCharacters1)).not.toMatchSchema(schema);
    expect(withRootOrgDomain(specialCharacters2)).not.toMatchSchema(schema);
  });

  it("should validate root CA domain prefix", () => {
    const withRootCADomainPrefix = (d: string) =>
      updatedBase((json: FabloConfigJson) => {
        json.rootOrg.ca.prefix = d;
      });

    expect(withRootCADomainPrefix(lettersOnly)).toMatchSchema(schema);
    expect(withRootCADomainPrefix(lettersAndNumber)).toMatchSchema(schema);
    expect(withRootCADomainPrefix(uppercase)).not.toMatchSchema(schema);
    expect(withRootCADomainPrefix(domain)).toMatchSchema(schema);
    expect(withRootCADomainPrefix(spaces)).not.toMatchSchema(schema);
    expect(withRootCADomainPrefix(specialCharacters1)).not.toMatchSchema(schema);
    expect(withRootCADomainPrefix(specialCharacters2)).not.toMatchSchema(schema);
  });

  it("should validate root orderer domain prefix", () => {
    const withRootOrdererDomainPrefix = (d: string) =>
      updatedBase((json: FabloConfigJson) => {
        json.ordererOrgs[0].orderer.prefix = d;
      });

    expect(withRootOrdererDomainPrefix(lettersOnly)).toMatchSchema(schema);
    expect(withRootOrdererDomainPrefix(lettersAndNumber)).toMatchSchema(schema);
    expect(withRootOrdererDomainPrefix(uppercase)).not.toMatchSchema(schema);
    expect(withRootOrdererDomainPrefix(domain)).toMatchSchema(schema);
    expect(withRootOrdererDomainPrefix(spaces)).not.toMatchSchema(schema);
    expect(withRootOrdererDomainPrefix(specialCharacters1)).not.toMatchSchema(schema);
    expect(withRootOrdererDomainPrefix(specialCharacters2)).not.toMatchSchema(schema);
  });

  it("should validate root orderer consensus type ", () => {
    const withRootOrdererConsensus = (c: string) =>
      updatedBase((json: FabloConfigJson) => {
        json.ordererOrgs[0].orderer.type = c as "solo" | "raft";
      });

    expect(withRootOrdererConsensus("solo")).toMatchSchema(schema);
    expect(withRootOrdererConsensus("raft")).toMatchSchema(schema);
    expect(withRootOrdererConsensus("kafka")).not.toMatchSchema(schema);
    expect(withRootOrdererConsensus(lettersOnly)).not.toMatchSchema(schema);
  });

  it("should validate root orderer number of instances", () => {
    const withRootOrdererNoOfInstances = (i: number) =>
      updatedBase((json: FabloConfigJson) => {
        json.ordererOrgs[0].orderer.instances = i;
      });

    expect(withRootOrdererNoOfInstances(1)).toMatchSchema(schema);
    expect(withRootOrdererNoOfInstances(10)).toMatchSchema(schema);
    expect(withRootOrdererNoOfInstances(0)).not.toMatchSchema(schema);
    expect(withRootOrdererNoOfInstances(11)).not.toMatchSchema(schema);
  });

  it("should validate org name", () => {
    const withOrgName = (n: string) =>
      updatedBase((json: FabloConfigJson) => {
        json.orgs[0].organization.name = n;
      });

    expect(withOrgName(lettersOnly)).toMatchSchema(schema);
    expect(withOrgName(lettersAndNumber)).toMatchSchema(schema);
    expect(withOrgName(uppercase)).toMatchSchema(schema);
    expect(withOrgName(domain)).not.toMatchSchema(schema);
    expect(withOrgName(spaces)).not.toMatchSchema(schema);
    expect(withOrgName(specialCharacters1)).not.toMatchSchema(schema);
    expect(withOrgName(specialCharacters2)).not.toMatchSchema(schema);
  });

  it("should validate org MSP name", () => {
    const withOrgMSPName = (n: string) =>
      updatedBase((json: FabloConfigJson) => {
        json.orgs[0].organization.mspName = n;
      });

    expect(withOrgMSPName(lettersOnly)).toMatchSchema(schema);
    expect(withOrgMSPName(lettersAndNumber)).toMatchSchema(schema);
    expect(withOrgMSPName(uppercase)).toMatchSchema(schema);
    expect(withOrgMSPName(domain)).not.toMatchSchema(schema);
    expect(withOrgMSPName(spaces)).not.toMatchSchema(schema);
    expect(withOrgMSPName(specialCharacters1)).not.toMatchSchema(schema);
    expect(withOrgMSPName(specialCharacters2)).not.toMatchSchema(schema);
  });

  it("should validate org domain", () => {
    const withOrgDomain = (d: string) =>
      updatedBase((json: FabloConfigJson) => {
        json.orgs[0].organization.domain = d;
      });

    expect(withOrgDomain(lettersOnly)).toMatchSchema(schema);
    expect(withOrgDomain(lettersAndNumber)).toMatchSchema(schema);
    expect(withOrgDomain(uppercase)).not.toMatchSchema(schema);
    expect(withOrgDomain(domain)).toMatchSchema(schema);
    expect(withOrgDomain(spaces)).not.toMatchSchema(schema);
    expect(withOrgDomain(specialCharacters1)).not.toMatchSchema(schema);
    expect(withOrgDomain(specialCharacters2)).not.toMatchSchema(schema);
  });

  it("should validate ca domain prefix", () => {
    const withCADomainPrefix = (d: string) =>
      updatedBase((json: FabloConfigJson) => {
        json.orgs[0].ca.prefix = d;
      });

    expect(withCADomainPrefix(lettersOnly)).toMatchSchema(schema);
    expect(withCADomainPrefix(lettersAndNumber)).toMatchSchema(schema);
    expect(withCADomainPrefix(uppercase)).not.toMatchSchema(schema);
    expect(withCADomainPrefix(domain)).toMatchSchema(schema);
    expect(withCADomainPrefix(spaces)).not.toMatchSchema(schema);
    expect(withCADomainPrefix(specialCharacters1)).not.toMatchSchema(schema);
    expect(withCADomainPrefix(specialCharacters2)).not.toMatchSchema(schema);
  });

  it("should validate peer domain prefix", () => {
    const withPeerDomainPrefix = (d: string) =>
      updatedBase((json: FabloConfigJson) => {
        json.orgs[0].peer.prefix = d;
      });

    expect(withPeerDomainPrefix(lettersOnly)).toMatchSchema(schema);
    expect(withPeerDomainPrefix(lettersAndNumber)).toMatchSchema(schema);
    expect(withPeerDomainPrefix(uppercase)).not.toMatchSchema(schema);
    expect(withPeerDomainPrefix(domain)).toMatchSchema(schema);
    expect(withPeerDomainPrefix(spaces)).not.toMatchSchema(schema);
    expect(withPeerDomainPrefix(specialCharacters1)).not.toMatchSchema(schema);
    expect(withPeerDomainPrefix(specialCharacters2)).not.toMatchSchema(schema);
  });

  it("should validate peer number of instances", () => {
    const withPeerNoOfInstances = (i: number) =>
      updatedBase((json: FabloConfigJson) => {
        json.orgs[0].peer.instances = i;
      });

    expect(withPeerNoOfInstances(1)).toMatchSchema(schema);
    expect(withPeerNoOfInstances(100)).toMatchSchema(schema);
    expect(withPeerNoOfInstances(0)).not.toMatchSchema(schema);
    expect(withPeerNoOfInstances(101)).not.toMatchSchema(schema);
  });

  it("should validate peer database type", () => {
    const withPeerDatabaseType = (db: string) =>
      updatedBase((json: FabloConfigJson) => {
        json.orgs[0].peer.db = db as "LevelDb" | "CouchDb";
      });

    expect(withPeerDatabaseType("LevelDb")).toMatchSchema(schema);
    expect(withPeerDatabaseType("CouchDb")).toMatchSchema(schema);
    expect(withPeerDatabaseType("MongoDb")).not.toMatchSchema(schema);
  });

  it("should validate peer tools", () => {
    const withTools = (tools: Record<string, unknown>) =>
      updatedBase((json: FabloConfigJson) => {
        json.orgs[0].tools = tools;
      });

    expect(withTools({ fabloRest: true })).toMatchSchema(schema);
    expect(withTools({ fabloRest: false })).toMatchSchema(schema);
    expect(withTools({})).toMatchSchema(schema);
    expect(withTools({ unknown: true })).not.toMatchSchema(schema);
  });

  it("should validate channel name - no spaces and capital letters", () => {
    const withChannelName = (n: string) =>
      updatedBase((json: FabloConfigJson) => {
        json.channels[0].name = n;
      });

    expect(withChannelName(lettersOnly)).toMatchSchema(schema);
    expect(withChannelName(lettersAndNumber)).toMatchSchema(schema);
    expect(withChannelName(uppercase)).not.toMatchSchema(schema); // no uppercase in channel name
    expect(withChannelName(domain)).not.toMatchSchema(schema);
    expect(withChannelName(spaces)).not.toMatchSchema(schema);
    expect(withChannelName(specialCharacters1)).not.toMatchSchema(schema);
    expect(withChannelName(specialCharacters2)).not.toMatchSchema(schema);
  });

  it("should validate chaincode name", () => {
    const withChaincodeName = (n: string) =>
      updatedBase((json: FabloConfigJson) => {
        json.chaincodes[0].name = n;
      });

    expect(withChaincodeName(lettersOnly)).toMatchSchema(schema);
    expect(withChaincodeName(lettersAndNumber)).toMatchSchema(schema);
    expect(withChaincodeName(uppercase)).toMatchSchema(schema);
    expect(withChaincodeName(domain)).not.toMatchSchema(schema);
    expect(withChaincodeName(spaces)).not.toMatchSchema(schema);
    expect(withChaincodeName(specialCharacters1)).not.toMatchSchema(schema);
    expect(withChaincodeName(specialCharacters2)).not.toMatchSchema(schema);
  });

  it("should validate chaincode version", () => {
    const withChaincodeVersion = (n: string) =>
      updatedBase((json: FabloConfigJson) => {
        json.chaincodes[0].version = n;
      });

    expect(withChaincodeVersion(lettersOnly)).toMatchSchema(schema);
    expect(withChaincodeVersion(lettersAndNumber)).toMatchSchema(schema);
    expect(withChaincodeVersion(uppercase)).toMatchSchema(schema);
    expect(withChaincodeVersion(domain)).toMatchSchema(schema);
    expect(withChaincodeVersion(spaces)).not.toMatchSchema(schema);
    expect(withChaincodeVersion(specialCharacters1)).not.toMatchSchema(schema);
    expect(withChaincodeVersion(specialCharacters2)).not.toMatchSchema(schema);
  });

  it("should validate chaincode language", () => {
    const withChaincodeLanguage = (l: string) =>
      updatedBase((json: FabloConfigJson) => {
        json.chaincodes[0].lang = l as "java" | "golang" | "node";
      });

    expect(withChaincodeLanguage("java")).toMatchSchema(schema);
    expect(withChaincodeLanguage("node")).toMatchSchema(schema);
    expect(withChaincodeLanguage("golang")).toMatchSchema(schema);
    expect(withChaincodeLanguage("cobol")).not.toMatchSchema(schema);
  });

  it("should validate chaincode initialization arguments", () => {
    const withChaincodeInitialization = (i: string) =>
      updatedBase((json: FabloConfigJson) => {
        json.chaincodes[0].init = i;
      });

    expect(withChaincodeInitialization(lettersOnly)).toMatchSchema(schema);
    expect(withChaincodeInitialization(lettersAndNumber)).toMatchSchema(schema);
    expect(withChaincodeInitialization(uppercase)).toMatchSchema(schema);
    expect(withChaincodeInitialization(domain)).toMatchSchema(schema);
    expect(withChaincodeInitialization(spaces)).toMatchSchema(schema);
    expect(withChaincodeInitialization(specialCharacters1)).toMatchSchema(schema);
    expect(withChaincodeInitialization(specialCharacters2)).toMatchSchema(schema);
  });

  it("should validate chaincode endorsement configuration", () => {
    const withChaincodeName = (n: string) =>
      updatedBase((json: FabloConfigJson) => {
        json.chaincodes[0].endorsement = n;
      });

    expect(withChaincodeName(lettersOnly)).toMatchSchema(schema);
    expect(withChaincodeName(lettersAndNumber)).toMatchSchema(schema);
    expect(withChaincodeName(uppercase)).toMatchSchema(schema);
    expect(withChaincodeName(domain)).toMatchSchema(schema);
    expect(withChaincodeName(spaces)).toMatchSchema(schema);
    expect(withChaincodeName(specialCharacters1)).toMatchSchema(schema);
    expect(withChaincodeName(specialCharacters2)).toMatchSchema(schema);
  });

  it("should validate chaincode directory", () => {
    const withChaincodeName = (n: string) =>
      updatedBase((json: FabloConfigJson) => {
        json.chaincodes[0].directory = n;
      });

    expect(withChaincodeName(lettersOnly)).toMatchSchema(schema);
    expect(withChaincodeName(lettersAndNumber)).toMatchSchema(schema);
    expect(withChaincodeName(uppercase)).toMatchSchema(schema);
    expect(withChaincodeName(domain)).toMatchSchema(schema);
    expect(withChaincodeName(spaces)).toMatchSchema(schema);
    expect(withChaincodeName(specialCharacters1)).toMatchSchema(schema);
    expect(withChaincodeName(specialCharacters2)).toMatchSchema(schema);
  });

  it("should validate chaincode private data", () => {
    const withNoPrivateData = () =>
      updatedBase((json: FabloConfigJson) => {
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        json.chaincodes[0] = { ...json.chaincodes[0], privateData: undefined };
      });
    const withPrivateData = (d: PrivateDataJson[]) =>
      updatedBase((json: FabloConfigJson) => {
        json.chaincodes[0].privateData = d;
      });
    const privateData = (name: string, ...orgNames: string[]) => ({ name, orgNames });
    const validOrgName = base.orgs[0].organization.name;
    const withPrivateDataName = (name: string) => withPrivateData([privateData(name, validOrgName)]);

    // various names
    expect(withPrivateDataName(lettersOnly)).toMatchSchema(schema);
    expect(withPrivateDataName(underscore)).toMatchSchema(schema);
    expect(withPrivateDataName(lettersAndNumber)).toMatchSchema(schema);
    expect(withPrivateDataName(uppercase)).toMatchSchema(schema);
    expect(withPrivateDataName(domain)).not.toMatchSchema(schema);
    expect(withPrivateDataName(spaces)).not.toMatchSchema(schema);
    expect(withPrivateDataName(specialCharacters1)).not.toMatchSchema(schema);
    expect(withPrivateDataName(specialCharacters2)).not.toMatchSchema(schema);

    // no private data, wrong object, two objects
    expect(withNoPrivateData()).toMatchSchema(schema);
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    expect(withPrivateData({ wrong: "obj" })).not.toMatchSchema(schema);
    expect(
      withPrivateData([privateData(lettersAndNumber, validOrgName), privateData(lettersOnly, validOrgName)]),
    ).toMatchSchema(schema);
  });
});
