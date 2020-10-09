const { performTests } = require('./performTests');

const label = 'network-03-simple-raft';

describe(label, () => {
  performTests(label, 'fabrikkaConfig-1org-1channel-1chaincode-tls-raft.json');
});
