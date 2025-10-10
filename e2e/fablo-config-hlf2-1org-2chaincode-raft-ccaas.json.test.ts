import performTests from "./performTests";

const config = "samples/fablo-config-hlf3-1org-2chaincode-raft-ccaas.json";

describe(config, () => {
  performTests(config);
});
