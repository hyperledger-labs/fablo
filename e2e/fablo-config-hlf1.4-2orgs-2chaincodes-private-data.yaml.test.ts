import performTests from "./performTests";

const config = "samples/fablo-config-hlf1.4-2orgs-2chaincodes-private-data.yaml";

describe(config, () => {
  performTests(config);
});
