const { performTests } = require('./performTests');

const label = 'network-06-2orgs-raft';

describe(label, () => {
  performTests(label, 'fabrikkaConfig-2orgs-2channels-1chaincode-tls-raft.json');
});
