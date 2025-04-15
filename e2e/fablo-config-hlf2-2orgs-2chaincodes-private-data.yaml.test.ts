import performTests from "./performTests";

const config = "samples/fablo-config-hlf2-2orgs-2chaincodes-private-data.yaml";

describe(config, () => {
  performTests(config);
});
