import performTests from "./performTests";

const config = "samples/fablo-config-hlf2-2orgs-2chaincodes-private-data-duplicate.yaml";

describe(config, () => {
  performTests(config);
});
