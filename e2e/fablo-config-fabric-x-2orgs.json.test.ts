import performTests from "./performTests";

const config = "samples/fablo-config-fabric-x-2orgs.json";

describe(config, () => {
  performTests(config);
});
