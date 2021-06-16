import performTests from "./performTests";

const config = "samples/fabrica-config-hlf1.4-2orgs-1chaincode.json";

describe(config, () => {
  performTests(config);
});
