import performTests from "./performTests";

const config = "samples/fabrica-config-hlf1.4-1org-1chaincode-raft.json";

describe(config, () => {
  performTests(config);
});
