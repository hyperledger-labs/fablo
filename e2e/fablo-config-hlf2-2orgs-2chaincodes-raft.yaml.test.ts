import performTests from "./performTests";

const config = "samples/fablo-config-hlf2-2orgs-2chaincodes-raft.yaml";

describe(config, () => {
  performTests(config);
});

const duplicateChaincodeConfig = "samples/fablo-config-hlf2-2orgs-2chaincodes-raft-duplicate.yaml";

describe(duplicateChaincodeConfig, () => {
  it("should throw an error for duplicate chaincode names across different channels", () => {
    expect(() => performTests(duplicateChaincodeConfig)).toThrowError(/Duplicate chaincode name found/);
  });
});
