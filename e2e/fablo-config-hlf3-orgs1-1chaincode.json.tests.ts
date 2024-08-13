import performTests from "./performTests";

const config = "samples/fablo-config-hlf3-1org-1chaincode.json";

describe(config, () => {
  performTests(config);
});
