const { performTests } = require('./performTests');

const label = 'network-09-2orgs-2chaincodes-raft-hlf2';

describe(label, () => {
  performTests(label, 'fabrikkaConfig-2orgs-2channels-2chaincodes-tls-raft-hlf2.json');
});
