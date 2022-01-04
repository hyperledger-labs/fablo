import performTests from "./performTests";

// TODO RENAME
const config = "samples/fablo-config-hlf2-1org-1chaincode-raft-explorer.json";

describe(config, () => {
  performTests(config);
});
