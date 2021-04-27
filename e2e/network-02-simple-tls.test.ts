import performTests from "./performTests";

const label = "network-02-simple-tls";

describe(label, () => {
  performTests(label, "fabricaConfig-1org-1channel-1chaincode-tls.json");
});
