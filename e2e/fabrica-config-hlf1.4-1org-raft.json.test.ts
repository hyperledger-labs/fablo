import performTests from "./performTests";

const config = "samples/fabrica-config-hlf1.4-1org-raft.json";

describe(config, () => {
  performTests(config);
});
