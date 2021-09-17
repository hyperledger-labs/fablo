import performTests from "./performTests";

const config = "samples/fablo-config-hlf1.4-2orgs-2chaincodes-raft.json";

describe(config, () => {
  performTests(config);
});
