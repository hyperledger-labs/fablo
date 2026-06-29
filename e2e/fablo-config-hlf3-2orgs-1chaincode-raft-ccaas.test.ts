import performTests from "./performTests";

const config = "samples/fablo-config-hlf3-2orgs-1chaincode-raft-ccaas.json";

describe(config, () => {
  performTests(config);
});
