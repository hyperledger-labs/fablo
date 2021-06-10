import performTests from "./performTests";

const config = "samples/fabrica-config-hlf1.4-2orgs-private-data.yaml";

describe(config, () => {
  performTests(config);
});
