import performTests from "./performTests";

const config = "samples/fabrica-config-hlf1.3-2orgs-private-data.json";

describe(config, () => {
  performTests(config);
});
