import performTests from "./performTests";

const config = "samples/fabrica-config-hlf2-2orgs-2chaincodes-raft.yaml";

describe(config, () => {
  performTests(config);
});
