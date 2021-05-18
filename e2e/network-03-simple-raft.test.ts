import performTests from "./performTests";

const label = "network-03-simple-raft";

describe(label, () => {
  performTests(label, "fabricaConfig-1org-1channel-1chaincode-tls-raft.json");
});
