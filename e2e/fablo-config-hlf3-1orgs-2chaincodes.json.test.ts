import performTests from "./performTests";

const config = "samples/fablo-config-hlf3-1orgs-2chaincodes.json";

describe(config, () => {
  performTests(config);
});
