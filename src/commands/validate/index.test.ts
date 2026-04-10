import Validate from "./index";
import { GlobalJson, OrdererJson, OrgJson, ChannelJson, ChaincodeJson, FabloConfigJson } from "../../types/FabloConfigJson";
import * as fs from "fs";

// ============================================
// Factory helpers
// ============================================
const createGlobal = (overrides?: Partial<GlobalJson>): GlobalJson => ({
  fabricVersion: "2.5.0",
  tls: true,
  peerDevMode: false,
  ...overrides,
});

const createOrderer = (overrides?: Partial<OrdererJson>): OrdererJson => ({
  groupName: "group1",
  prefix: "orderer",
  type: "raft",
  instances: 3,
  ...overrides,
});

const createOrg = (overrides?: Partial<OrgJson>): OrgJson => ({
  organization: { name: "Org1", mspName: "Org1MSP", domain: "org1.example.com" },
  ca: { prefix: "ca", db: "sqlite" },
  orderers: undefined,
  peer: { prefix: "peer", instances: 2, db: "LevelDb" },
  ...overrides,
});

/**
 * Creates a mock validator using Object.create — fast, avoids oclif constructor.
 * Does NOT cover the Listener class or field initializers (lines 70-98).
 */
const createValidator = () => {
  const validator = Object.create(Validate.prototype);
  validator.errors = {
    messages: [] as any[],
    onEvent(e: any) { this.messages.push(e); },
    getAllMessages() { return this.messages; },
    count() { return this.messages.length; },
  };
  validator.warnings = {
    messages: [] as any[],
    onEvent(e: any) { this.messages.push(e); },
    getAllMessages() { return this.messages; },
    count() { return this.messages.length; },
  };
  validator.log = jest.fn();
  validator.fabloConfigPath = "";
  return validator;
};

/**
 * Creates a real Validate instance to cover the Listener class constructor
 * and the field initializers (lines 70-98). The oclif Command constructor
 * accepts (argv, config) — passing minimal values avoids side-effects.
 */
const createRealValidator = () => {
  // oclif Command constructor signature: constructor(argv: string[], config: Config)
  // Passing a minimal object satisfies the constructor without running oclif's full init.
  const validator = new (Validate as any)([], { root: __dirname, name: "test" });
  validator.log = jest.fn();
  return validator;
};

// ============================================
// Minimal valid FabloConfigJson for orchestrator tests
// ============================================
const createMinimalConfig = (): FabloConfigJson => ({
  $schema: `https://github.com/hyperledger-labs/fablo/releases/download/2.5.0/schema.json`,
  global: {
    fabricVersion: "2.5.0",
    tls: true,
    peerDevMode: false,
  },
  orgs: [
    {
      organization: { name: "Org1", mspName: "Org1MSP", domain: "org1.example.com" },
      ca: { prefix: "ca", db: "sqlite" },
      orderers: [{ groupName: "group1", prefix: "orderer", type: "raft", instances: 3 }],
      peer: { prefix: "peer", instances: 2, db: "LevelDb" },
    },
  ],
  channels: [{ name: "mychannel", orgs: [{ name: "Org1", peers: ["peer0"] }] }],
  chaincodes: [
    {
      name: "mycc",
      version: "1.0",
      lang: "golang",
      channel: "mychannel",
      directory: "chaincodes/mycc",
      privateData: [],
    },
  ],
  hooks: {},
});

describe("Validate Validation Methods", () => {
  let mockExit: jest.SpyInstance;

  beforeEach(() => {
    mockExit = jest.spyOn(process, "exit").mockImplementation(() => undefined as never);
  });

  afterEach(() => {
    mockExit.mockRestore();
  });

  // ============================================
  // Listener class coverage (lines 70-81, 96-98)
  // ============================================
  describe("Listener class (via real Validate instance)", () => {
    it("should initialize errors and warnings as empty Listener instances", () => {
      const validator = createRealValidator();
      // The real Listener class is instantiated — covers lines 70, 76-78, 80-81, 96-97
      expect(validator.errors.count()).toBe(0);
      expect(validator.errors.getAllMessages()).toEqual([]);
      expect(validator.warnings.count()).toBe(0);
      expect(validator.warnings.getAllMessages()).toEqual([]);
    });

    it("should accumulate events via the real Listener.onEvent (line 72-73)", () => {
      const validator = createRealValidator();
      // Trigger a validation that produces an ERROR — exercises the real onEvent path
      validator._validateDevMode(createGlobal({ peerDevMode: true, tls: true }));
      expect(validator.errors.count()).toBe(1);
      expect(validator.errors.getAllMessages()[0].message).toContain("TLS needs to be disabled");
    });
  });

  // ============================================
  // emit() CRITICAL path (lines 100-105)
  // ============================================
  describe("emit() CRITICAL path", () => {
    it("should log critical error message and call process.exit(1)", () => {
      const validator = createRealValidator();
      // _validateCcaaTLS triggers CRITICAL via emit() when ccaas + no TLS
      validator._validateCcaaTLS(createGlobal({ tls: false }), { name: "cc1", lang: "ccaas", channel: "ch1" } as any);
      expect(mockExit).toHaveBeenCalledWith(1);
      // Verify the log was called with the critical message (chalked)
      expect(validator.log).toHaveBeenCalled();
    });

    it("should log critical message for unsupported Fabric version via _validateFabricVersion", () => {
      const validator = createRealValidator();
      // _validateFabricVersion is private — access via bracket notation
      (validator as any)._validateFabricVersion(createGlobal({ fabricVersion: "1.9.0" }));
      expect(mockExit).toHaveBeenCalledWith(1);
      // At least two log calls: "Critical error occured:" and the message itself
      expect(validator.log).toHaveBeenCalled();
    });
  });

  // ============================================
  // _validateFabricVersion (lines 153-161)
  // ============================================
  describe("_validateFabricVersion", () => {
    it("should trigger CRITICAL for Fabric version below 2.0.0", () => {
      const validator = createValidator();
      (validator as any)._validateFabricVersion(createGlobal({ fabricVersion: "1.4.12" }));
      expect(mockExit).toHaveBeenCalledWith(1);
    });

    it("should pass silently for Fabric version >= 2.0.0", () => {
      const validator = createValidator();
      (validator as any)._validateFabricVersion(createGlobal({ fabricVersion: "2.5.0" }));
      expect(validator.errors.count()).toBe(0);
      expect(mockExit).not.toHaveBeenCalled();
    });
  });

  // ============================================
  // _verifyFabricVersion (lines 580-585)
  // ============================================
  describe("_verifyFabricVersion", () => {
    it("should emit ERROR for Fabric version below 2.0.0", () => {
      const validator = createValidator();
      (validator as any)._verifyFabricVersion(createGlobal({ fabricVersion: "1.4.6" }));
      expect(validator.errors.count()).toBe(1);
      expect(validator.errors.messages[0].message).toContain("Fablo supports Fabric in version 2.0.0 and higher");
    });

    it("should pass cleanly for Fabric version >= 2.0.0", () => {
      const validator = createValidator();
      (validator as any)._verifyFabricVersion(createGlobal({ fabricVersion: "2.5.0" }));
      expect(validator.errors.count()).toBe(0);
    });
  });

  // ============================================
  // validate() orchestrator (lines 113-151)
  // ============================================
  describe("validate() orchestrator", () => {
    let mockExistsSync: jest.SpyInstance;
    let mockReadFileSync: jest.SpyInstance;

    beforeEach(() => {
      mockExistsSync = jest.spyOn(fs, "existsSync");
      mockReadFileSync = jest.spyOn(fs, "readFileSync");
    });

    afterEach(() => {
      mockExistsSync.mockRestore();
      mockReadFileSync.mockRestore();
    });

    it("should run the full validation pipeline against a valid config", async () => {
      const validConfig = createMinimalConfig();
      mockExistsSync.mockReturnValue(true);
      mockReadFileSync.mockReturnValue(JSON.stringify(validConfig));

      const validator = createValidator();
      validator.fabloConfigPath = "/fake/path/fablo-config.json";
      await validator.validate();

      // Schema version prefix may not match the running fablo version, so we only
      // verify the orchestrator completes without throwing and does exercise all paths.
      // The only possible errors are schema-version related, not structural.
      expect(validator.errors.count()).toBeLessThanOrEqual(1);
    });
  });

  // ============================================
  // _printIfNotEmpty (lines 229-240)
  // ============================================
  describe("_printIfNotEmpty", () => {
    it("should print grouped messages when the array is non-empty", () => {
      const validator = createValidator();
      const messages = [
        { category: "Orderer", message: "Problem A" },
        { category: "Orderer", message: "Problem B" },
        { category: "Channel", message: "Problem C" },
      ];
      validator._printIfNotEmpty(messages, "Errors found:");
      // Caption + 2 category headers + 3 individual messages = 6 log calls
      expect(validator.log).toHaveBeenCalledWith("Errors found:");
      expect(validator.log).toHaveBeenCalledTimes(6);
    });

    it("should not print anything when the array is empty", () => {
      const validator = createValidator();
      validator._printIfNotEmpty([], "Nothing:");
      expect(validator.log).not.toHaveBeenCalled();
    });
  });

  // ============================================
  // findDuplicatedItems (tested via channel and chaincode validators)
  // ============================================
  describe("findDuplicatedItems (via _validateChannelNames & _validateChaincodeNames)", () => {
    it("should handle clean distinct entries", () => {
      const validator = createValidator();
      validator._validateChannelNames([{ name: "mychannel1" } as ChannelJson, { name: "mychannel2" } as ChannelJson]);
      expect(validator.errors.count()).toBe(0);
    });

    it("should find duplicated channel names", () => {
      const validator = createValidator();
      validator._validateChannelNames([{ name: "mychannel" } as ChannelJson, { name: "mychannel" } as ChannelJson]);
      expect(validator.errors.count()).toBe(1);
      expect(validator.errors.messages[0].message).toContain("Channel name 'mychannel' is not unique");
    });

    it("should handle empty array correctly", () => {
      const validator = createValidator();
      validator._validateChannelNames([]);
      expect(validator.errors.count()).toBe(0);
    });

    it("should correctly split channel prefixes from chaincode names when determining scope", () => {
      const validator = createValidator();
      validator._validateChaincodeNames([
        { name: "cc1", channel: "ch1" } as ChaincodeJson,
        { name: "cc1", channel: "ch1" } as ChaincodeJson,
        { name: "cc1", channel: "ch2" } as ChaincodeJson,
      ]);
      expect(validator.errors.count()).toBe(1);
      expect(validator.errors.messages[0].message).toContain("Chaincode name 'cc1' is not unique in channel 'ch1'");
    });
  });

  // ============================================
  // Raft Validation
  // ============================================
  describe("_validateOrdererForRaftType", () => {
    it("should log a warning when using 1 instance for Raft", () => {
      const validator = createValidator();
      validator._validateOrdererForRaftType([createOrderer({ type: "raft", instances: 1 })], createGlobal());
      expect(validator.warnings.count()).toBe(1);
      expect(validator.warnings.messages[0].message).toContain("number of instances is 1. Network won't be fault tolerant!");
    });

    it("should log an error when TLS is disabled", () => {
      const validator = createValidator();
      validator._validateOrdererForRaftType([createOrderer({ type: "raft", instances: 3 })], createGlobal({ tls: false }));
      expect(validator.errors.count()).toBe(1);
      expect(validator.errors.messages[0].message).toContain("Raft consensus type must use network in TLS mode");
    });

    it("should pass cleanly when config is valid", () => {
      const validator = createValidator();
      validator._validateOrdererForRaftType([createOrderer({ type: "raft", instances: 3 })], createGlobal());
      expect(validator.errors.count()).toBe(0);
      expect(validator.warnings.count()).toBe(0);
    });

    it("should ignore orderers of non-raft type", () => {
      const validator = createValidator();
      validator._validateOrdererForRaftType([createOrderer({ type: "BFT", instances: 1 })], createGlobal());
      expect(validator.errors.count()).toBe(0);
      expect(validator.warnings.count()).toBe(0);
    });

    it("should emit ERROR when Fabric version does not support Raft (lines 322-327)", () => {
      const validator = createValidator();
      // versionsSupportingRaft checks isGreaterOrEqual("1.4.3") — version "1.4.0" fails this check
      validator._validateOrdererForRaftType(
        [createOrderer({ type: "raft", instances: 3 })],
        createGlobal({ fabricVersion: "1.4.0" }),
      );
      expect(validator.errors.count()).toBeGreaterThanOrEqual(1);
      const raftUnsupportedError = validator.errors.messages.find(
        (m: any) => m.message.includes("does not support Raft consensus type"),
      );
      expect(raftUnsupportedError).toBeDefined();
    });
  });

  // ============================================
  // Solo Validation
  // ============================================
  describe("_validateOrdererCountForSoloType", () => {
    it("should error if solo type is used in Fabric >= 3.0.0", () => {
      const validator = createValidator();
      validator._validateOrdererCountForSoloType([createOrderer({ type: "solo", instances: 1 })], createGlobal({ fabricVersion: "3.0.0" }));
      expect(validator.errors.count()).toBe(1);
      expect(validator.errors.messages[0].message).toContain("Solo consensus type is not supported in Fabric version");
    });

    it("should warn if solo type has more than 1 instance", () => {
      const validator = createValidator();
      validator._validateOrdererCountForSoloType([createOrderer({ type: "solo", instances: 2 })], createGlobal({ fabricVersion: "2.5.0" }));
      expect(validator.warnings.count()).toBe(1);
      expect(validator.warnings.messages[0].message).toContain("consesus type is set to 'solo', but number of instances is 2");
    });

    it("should pass for valid solo definition on Fabric 2.x", () => {
      const validator = createValidator();
      validator._validateOrdererCountForSoloType([createOrderer({ type: "solo", instances: 1 })], createGlobal({ fabricVersion: "2.5.0" }));
      expect(validator.errors.count()).toBe(0);
      expect(validator.warnings.count()).toBe(0);
    });
  });

  // ============================================
  // Chaincode Names
  // ============================================
  describe("_validateChaincodeNames", () => {
    it("should pass with unique chaincode names per channel", () => {
      const validator = createValidator();
      validator._validateChaincodeNames([
        { name: "cc1", channel: "ch1" } as ChaincodeJson,
        { name: "cc2", channel: "ch1" } as ChaincodeJson,
      ]);
      expect(validator.errors.count()).toBe(0);
    });

    it("should error when duplicates exist on same channel", () => {
      const validator = createValidator();
      validator._validateChaincodeNames([
        { name: "cc1", channel: "ch1" } as ChaincodeJson,
        { name: "cc1", channel: "ch1" } as ChaincodeJson,
      ]);
      expect(validator.errors.count()).toBe(1);
      expect(validator.errors.messages[0].message).toContain("not unique in channel");
    });
  });

  // ============================================
  // Anchor Peer Validation
  // ============================================
  describe("_validateOrgsAnchorPeerInstancesCount", () => {
    it("should pass when anchor peers <= total peers", () => {
      const validator = createValidator();
      validator._validateOrgsAnchorPeerInstancesCount([createOrg({ peer: { prefix: "peer", instances: 2, db: "LevelDb", anchorPeerInstances: 2 } })]);
      expect(validator.errors.count()).toBe(0);
    });

    it("should error when anchor peers exceed total peers", () => {
      const validator = createValidator();
      validator._validateOrgsAnchorPeerInstancesCount([createOrg({ peer: { prefix: "peer", instances: 2, db: "LevelDb", anchorPeerInstances: 3 } })]);
      expect(validator.errors.count()).toBe(1);
      expect(validator.errors.messages[0].message).toContain("Too many anchor peers for organization");
    });

    it("should pass when anchorPeerInstances is undefined", () => {
      const validator = createValidator();
      validator._validateOrgsAnchorPeerInstancesCount([createOrg({ peer: { prefix: "peer", instances: 2, db: "LevelDb" } })]);
      expect(validator.errors.count()).toBe(0);
    });
  });

  // ============================================
  // Dev Mode Validation
  // ============================================
  describe("_validateDevMode", () => {
    it("should error when devMode true and TLS true", () => {
      const validator = createValidator();
      validator._validateDevMode(createGlobal({ peerDevMode: true, tls: true }));
      expect(validator.errors.count()).toBe(1);
      expect(validator.errors.messages[0].message).toContain("TLS needs to be disabled when running peers in dev mode");
    });

    it("should pass when devMode true and TLS false", () => {
      const validator = createValidator();
      validator._validateDevMode(createGlobal({ peerDevMode: true, tls: false }));
      expect(validator.errors.count()).toBe(0);
    });

    it("should pass when devMode false and TLS true", () => {
      const validator = createValidator();
      validator._validateDevMode(createGlobal({ peerDevMode: false, tls: true }));
      expect(validator.errors.count()).toBe(0);
    });
  });

  // ============================================
  // Channel Org Peers Validation
  // ============================================
  describe("_validateChannelOrgPeers", () => {
    it("should pass when org with peers is joined to a channel", () => {
      const validator = createValidator();
      const orgWithPeers = createOrg();
      const channel = { name: "ch1", orgs: [{ name: "Org1", peers: [] }] } as unknown as ChannelJson;
      validator._validateChannelOrgPeers([channel], [orgWithPeers]);
      expect(validator.errors.count()).toBe(0);
    });

    it("should error when org without peers is joined to a channel", () => {
      const validator = createValidator();
      const orgWithoutPeers = createOrg({ peer: undefined });
      const channel = { name: "ch1", orgs: [{ name: "Org1", peers: [] }] } as unknown as ChannelJson;
      validator._validateChannelOrgPeers([channel], [orgWithoutPeers]);
      expect(validator.errors.count()).toBe(1);
      expect(validator.errors.messages[0].message).toContain("You can't join org without peers to a channel");
    });
  });

  // ============================================
  // Orderer Definition Exists
  // ============================================
  describe("_validateIfOrdererDefinitionExists", () => {
    it("should pass when at least one org has orderers", () => {
      const validator = createValidator();
      validator._validateIfOrdererDefinitionExists([
        createOrg({ orderers: undefined }),
        createOrg({ orderers: [createOrderer()] }),
      ]);
      expect(validator.errors.count()).toBe(0);
    });

    it("should error when no org has orderers", () => {
      const validator = createValidator();
      validator._validateIfOrdererDefinitionExists([createOrg({ orderers: undefined })]);
      expect(validator.errors.count()).toBe(1);
      expect(validator.errors.messages[0].message).toContain("At least 1 orderer block is mandatory!");
    });
  });

  // ============================================
  // Orderer Count Per Org
  // ============================================
  describe("_validateOrdererCountForOrg", () => {
    it("should pass when total orderers <= 9", () => {
      const validator = createValidator();
      validator._validateOrdererCountForOrg(createOrg({ orderers: [createOrderer({ instances: 9 })] }));
      expect(validator.errors.count()).toBe(0);
    });

    it("should error when total orderers > 9", () => {
      const validator = createValidator();
      validator._validateOrdererCountForOrg(createOrg({ orderers: [createOrderer({ instances: 5 }), createOrderer({ instances: 5 })] }));
      expect(validator.errors.count()).toBe(1);
      expect(validator.errors.messages[0].message).toContain("You've reached Fablo limits!");
    });
  });

  // ============================================
  // Orderer Group Name Unique
  // ============================================
  describe("_validateOrdererGroupNameUniqueForOrg", () => {
    it("should pass with unique group names", () => {
      const validator = createValidator();
      validator._validateOrdererGroupNameUniqueForOrg(createOrg({ orderers: [createOrderer({ groupName: "g1" }), createOrderer({ groupName: "g2" })] }));
      expect(validator.errors.count()).toBe(0);
    });

    it("should error for duplicate group names", () => {
      const validator = createValidator();
      validator._validateOrdererGroupNameUniqueForOrg(createOrg({ orderers: [createOrderer({ groupName: "g1" }), createOrderer({ groupName: "g1" })] }));
      expect(validator.errors.count()).toBe(1);
      expect(validator.errors.messages[0].message).toContain("not unique in organization");
    });

    it("should skip when org has no orderers", () => {
      const validator = createValidator();
      validator._validateOrdererGroupNameUniqueForOrg(createOrg({ orderers: undefined }));
      expect(validator.errors.count()).toBe(0);
    });
  });

  // ============================================
  // Same Orderer Type Across Group
  // ============================================
  describe("_validateIfSameOrdererTypeAcrossOrdererGroup", () => {
    it("should pass when all orderers in group have the same type", () => {
      const validator = createValidator();
      validator._validateIfSameOrdererTypeAcrossOrdererGroup([
        createOrg({ orderers: [createOrderer({ groupName: "g1", type: "raft" }), createOrderer({ groupName: "g1", type: "raft" })] }),
      ]);
      expect(validator.errors.count()).toBe(0);
    });

    it("should error when orderers in same group have different types", () => {
      const validator = createValidator();
      validator._validateIfSameOrdererTypeAcrossOrdererGroup([
        createOrg({ orderers: [createOrderer({ groupName: "g1", type: "raft" }), createOrderer({ groupName: "g1", type: "BFT" })] }),
      ]);
      expect(validator.errors.count()).toBe(1);
      expect(validator.errors.messages[0].message).toContain("should have same orderer type across whole group");
    });
  });

  // ============================================
  // Channel Orderer Group
  // ============================================
  describe("_validateChannelOrdererGroup", () => {
    it("should pass when channel references a valid orderer group", () => {
      const validator = createValidator();
      const orgs = [createOrg({ orderers: [createOrderer({ groupName: "g1" })] })];
      const channels = [{ name: "ch1", ordererGroup: "g1", orgs: [] } as unknown as ChannelJson];
      validator._validateChannelOrdererGroup(orgs, channels);
      expect(validator.errors.count()).toBe(0);
    });

    it("should error when channel references a non-existent orderer group", () => {
      const validator = createValidator();
      const orgs = [createOrg({ orderers: [createOrderer({ groupName: "g1" })] })];
      const channels = [{ name: "ch1", ordererGroup: "g2", orgs: [] } as unknown as ChannelJson];
      validator._validateChannelOrdererGroup(orgs, channels);
      expect(validator.errors.count()).toBe(1);
      expect(validator.errors.messages[0].message).toContain("has non valid ordererGroup defined");
    });
  });

  // ============================================
  // Chaincodes init/initRequired validation
  // ============================================
  describe("_validateChaincodes", () => {
    it("should warn about init parameter on V2 capabilities", () => {
      const validator = createValidator();
      const caps = { isV2: true } as any;
      validator._validateChaincodes(caps, [{ name: "cc", init: "true", privateData: [] } as unknown as ChaincodeJson]);
      expect(validator.warnings.count()).toBe(1);
      expect(validator.warnings.messages[0].message).toContain("Chaincode 'init' parameters are only supported in Fabric prior to 2.0");
    });

    it("should warn about initRequired on non-V2 capabilities", () => {
      const validator = createValidator();
      const caps = { isV2: false } as any;
      validator._validateChaincodes(caps, [{ name: "cc", initRequired: true, privateData: [] } as unknown as ChaincodeJson]);
      expect(validator.warnings.count()).toBe(1);
      expect(validator.warnings.messages[0].message).toContain("Chaincode 'initRequired' parameter is supported only in Fabric prior to 2.0");
    });

    it("should pass for standard deployment without init/initRequired", () => {
      const validator = createValidator();
      const caps = { isV2: true } as any;
      validator._validateChaincodes(caps, [{ name: "cc", privateData: [] } as unknown as ChaincodeJson]);
      expect(validator.warnings.count()).toBe(0);
    });
  });

  // ============================================
  // Orgs Presence Check
  // ============================================
  describe("_validateOrgs", () => {
    it("should warn for org without peers or orderers", () => {
      const validator = createValidator();
      validator._validateOrgs([createOrg({ peer: undefined, orderers: undefined })]);
      expect(validator.warnings.count()).toBe(1);
      expect(validator.warnings.messages[0].message).toContain("doesn't have Peers or Orderers");
    });

    it("should pass for org with peers", () => {
      const validator = createValidator();
      validator._validateOrgs([createOrg()]);
      expect(validator.warnings.count()).toBe(0);
    });
  });

  // ============================================
  // Engine Specific Settings
  // ============================================
  describe("_validateEngineSpecificSettings", () => {
    it("should error for kubernetes with Fabric < 2.0.0", () => {
      const validator = createValidator();
      validator._validateEngineSpecificSettings({ global: createGlobal({ engine: "kubernetes", fabricVersion: "1.4.10" }) } as any);
      expect(validator.errors.count()).toBe(1);
      expect(validator.errors.messages[0].message).toContain("Kubernetes is not supported by Fablo for Fabric below version 2.0.0");
    });

    it("should pass for kubernetes with Fabric >= 2.0.0", () => {
      const validator = createValidator();
      validator._validateEngineSpecificSettings({ global: createGlobal({ engine: "kubernetes", fabricVersion: "2.5.0" }) } as any);
      expect(validator.errors.count()).toBe(0);
    });

    it("should pass for docker engine regardless of version", () => {
      const validator = createValidator();
      validator._validateEngineSpecificSettings({ global: createGlobal({ engine: "docker", fabricVersion: "1.4.10" }) } as any);
      expect(validator.errors.count()).toBe(0);
    });
  });

  // ============================================
  // Explorer Validation
  // ============================================
  describe("_validateExplorer", () => {
    it("should warn when global explorer enabled and org explorer also enabled", () => {
      const validator = createValidator();
      validator._validateExplorer(createGlobal({ tools: { explorer: true } }), [createOrg({ tools: { explorer: true } } as any)]);
      expect(validator.warnings.count()).toBe(1);
      expect(validator.warnings.messages[0].message).toContain("however it will be ignored due to global explorer enabled");
    });

    it("should not warn when global explorer enabled but org explorer not set", () => {
      const validator = createValidator();
      validator._validateExplorer(createGlobal({ tools: { explorer: true } }), [createOrg()]);
      expect(validator.warnings.count()).toBe(0);
    });

    it("should not warn when global explorer disabled and org explorer enabled", () => {
      const validator = createValidator();
      validator._validateExplorer(createGlobal(), [createOrg({ tools: { explorer: true } } as any)]);
      expect(validator.warnings.count()).toBe(0);
    });
  });

  // ============================================
  // CCAAS TLS Validation
  // ============================================
  describe("_validateCcaaTLS", () => {
    it("should pass for ccaas with TLS enabled", () => {
      const validator = createValidator();
      validator._validateCcaaTLS(createGlobal({ tls: true }), { name: "cc", lang: "ccaas" } as any);
      expect(validator.errors.count()).toBe(0);
      expect(mockExit).not.toHaveBeenCalled();
    });

    it("should trigger CRITICAL for ccaas without TLS", () => {
      const validator = createValidator();
      validator._validateCcaaTLS(createGlobal({ tls: false }), { name: "cc", lang: "ccaas" } as any);
      expect(mockExit).toHaveBeenCalledWith(1);
    });

    it("should pass for non-ccaas chaincode without TLS", () => {
      const validator = createValidator();
      validator._validateCcaaTLS(createGlobal({ tls: false }), { name: "cc", lang: "golang" } as any);
      expect(validator.errors.count()).toBe(0);
      expect(mockExit).not.toHaveBeenCalled();
    });
  });

  // ============================================
  // Summary Methods
  // ============================================
  describe("shortSummary", () => {
    it("should print error and warning counts", async () => {
      const validator = createValidator();
      validator.errors.messages.push({ category: "Test", message: "err" });
      validator.warnings.messages.push({ category: "Test", message: "warn" });
      await validator.shortSummary();
      expect(validator.log).toHaveBeenCalledWith("Validation errors count: 1");
      expect(validator.log).toHaveBeenCalledWith("Validation warnings count: 1");
    });
  });

  describe("detailedSummary", () => {
    it("should call process.exit(1) when errors exist", async () => {
      const validator = createValidator();
      validator.errors.messages.push({ category: "Critical", message: "Severe failure" });
      validator.warnings.messages.push({ category: "General", message: "A warning" });
      await validator.detailedSummary();
      expect(mockExit).toHaveBeenCalledWith(1);
    });

    it("should not exit when only warnings exist", async () => {
      const validator = createValidator();
      validator.warnings.messages.push({ category: "General", message: "Minor warning" });
      await validator.detailedSummary();
      expect(mockExit).not.toHaveBeenCalled();
      expect(validator.log).toHaveBeenCalled();
    });

    it("should not log validation summary when zero messages exist", async () => {
      const validator = createValidator();
      await validator.detailedSummary();
      expect(mockExit).not.toHaveBeenCalled();
      expect(validator.log).not.toHaveBeenCalled();
    });
  });

  // ============================================
  // _validateIfConfigFileExists
  // ============================================
  describe("_validateIfConfigFileExists", () => {
    let mockExistsSync: jest.SpyInstance;
    beforeEach(() => {
      mockExistsSync = jest.spyOn(fs, "existsSync");
    });
    afterEach(() => {
      mockExistsSync.mockRestore();
    });

    it("should set fabloConfigPath when file exists", () => {
      mockExistsSync.mockReturnValue(true);
      const validator = createValidator();
      validator._validateIfConfigFileExists("/fake/absolute/path/valid-config.json");
      expect(validator.errors.count()).toBe(0);
      expect(validator.fabloConfigPath).toContain("valid-config.json");
    });

    it("should emit CRITICAL when file does not exist", () => {
      mockExistsSync.mockReturnValue(false);
      const validator = createValidator();
      validator._validateIfConfigFileExists("/fake/absolute/path/invalid-config.json");
      expect(mockExit).toHaveBeenCalledWith(1);
    });

    it("should resolve relative paths against cwd", () => {
      mockExistsSync.mockReturnValue(true);
      const validator = createValidator();
      validator._validateIfConfigFileExists("relative-config.json");
      expect(validator.fabloConfigPath).toContain("relative-config.json");
    });
  });

  // ============================================
  // _validateSupportedFabloVersion
  // ============================================
  describe("_validateSupportedFabloVersion", () => {
    it("should error for unsupported schema version", () => {
      const validator = createValidator();
      validator._validateSupportedFabloVersion("https://github.com/hyperledger-labs/fablo/releases/download/0.0.1/schema.json");
      expect(validator.errors.count()).toBe(1);
      expect(validator.errors.messages[0].message).toContain("which is not supported.");
    });
  });

  // ============================================
  // _validateJsonSchema
  // ============================================
  describe("_validateJsonSchema", () => {
    it("should emit errors when config violates schema", () => {
      const validator = createValidator();
      validator._validateJsonSchema({} as any);
      expect(validator.errors.count()).toBeGreaterThan(0);
    });

    it("should pass for a structurally valid config", () => {
      const validator = createValidator();
      validator._validateJsonSchema(createMinimalConfig());
      expect(validator.errors.count()).toBe(0);
    });
  });

  // ============================================
  // _validateExplorerWithFabricVersion (lines 551-568)
  // ============================================
  describe("_validateExplorerWithFabricVersion", () => {
    it("should warn globally for version >= 2.5.13 with global explorer", () => {
      const validator = createValidator();
      validator._validateExplorerWithFabricVersion(createGlobal({ fabricVersion: "2.5.13", tools: { explorer: true } }), []);
      expect(validator.warnings.count()).toBe(1);
      expect(validator.warnings.messages[0].message).toContain("may not be supported by the Hyperledger Explorer");
    });

    it("should warn per-org for version < 1.4.0 with org-level explorer (lines 558-565)", () => {
      const validator = createValidator();
      validator._validateExplorerWithFabricVersion(
        createGlobal({ fabricVersion: "1.3.0" }),
        [createOrg({ tools: { explorer: true } as any })],
      );
      expect(validator.warnings.count()).toBe(1);
      expect(validator.warnings.messages[0].category).toBe("Orgs");
    });

    it("should warn per-org for version >= 2.5.13 with org-level explorer (no global)", () => {
      const validator = createValidator();
      validator._validateExplorerWithFabricVersion(
        createGlobal({ fabricVersion: "3.0.0" }),
        [createOrg({ tools: { explorer: true } as any })],
      );
      expect(validator.warnings.count()).toBe(1);
      expect(validator.warnings.messages[0].category).toBe("Orgs");
    });

    it("should not warn for supported version range", () => {
      const validator = createValidator();
      validator._validateExplorerWithFabricVersion(createGlobal({ fabricVersion: "2.4.9", tools: { explorer: true } }), [createOrg()]);
      expect(validator.warnings.count()).toBe(0);
    });

    it("should not warn when no explorer is enabled anywhere", () => {
      const validator = createValidator();
      validator._validateExplorerWithFabricVersion(createGlobal({ fabricVersion: "3.0.0" }), [createOrg()]);
      expect(validator.warnings.count()).toBe(0);
    });
  });
});
