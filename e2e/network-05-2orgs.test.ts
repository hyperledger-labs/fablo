import performTests from "./performTests";

const label = "network-05-2orgs";

describe(label, () => {
  performTests(label, "fabricaConfig-2orgs-2channels-1chaincode.json");
});
