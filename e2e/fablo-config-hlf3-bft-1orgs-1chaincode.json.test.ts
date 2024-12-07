import performTests from "./performTests";

const config = "samples/fablo-config-hlf3-bft-1orgs-1chaincode.json";

describe(config, () => {
  performTests(config);
});
