import performTests from "./performTests";

const config = "samples/fablo-config-hlf3-1org-external-ca.json";

describe(config, () => {
  performTests(config);
});
