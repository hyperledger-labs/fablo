import performTests from "./performTests";

const config = "samples/fablo-config-hlf1.3-2orgs-1chaincode-private-data.json";

describe(config, () => {
  performTests(config);
});
