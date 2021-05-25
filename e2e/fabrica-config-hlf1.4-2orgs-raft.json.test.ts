import performTests from "./performTests";

const config = "samples/fabrica-config-hlf1.4-2orgs-raft.json";

describe(config, () => {
  performTests(config);
});
