import performTests from "./performTests";

const label = "network-07-2orgs-raft";

describe(label, () => {
  performTests(label, "fabricaConfig-2orgs-2channels-2chaincodes-tls-raft.json");
});
