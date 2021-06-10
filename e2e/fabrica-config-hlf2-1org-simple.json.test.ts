import performTests from "./performTests";

const config = "samples/fabrica-config-hlf2-1org-simple.json";

describe(config, () => {
  performTests(config);
});
