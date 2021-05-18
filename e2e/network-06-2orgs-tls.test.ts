import performTests from "./performTests";

const label = "network-06-2orgs-tls";

describe(label, () => {
  performTests(label, "fabricaConfig-2orgs-2channels-1chaincode-tls.json");
});
