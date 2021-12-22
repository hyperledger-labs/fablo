import performTests from "./performTests";

const config = "samples/fablo-config-hlf2-3orgs-1chaincode-raft-explorer.json";

describe(config, () => {
  performTests(config);
});
