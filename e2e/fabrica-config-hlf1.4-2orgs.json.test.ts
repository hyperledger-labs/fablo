import performTests from "./performTests";

const config = "samples/fabrica-config-hlf1.4-2orgs.json";

describe(config, () => {
  performTests(config);
});
