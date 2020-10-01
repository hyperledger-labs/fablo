const { performTests } = require('./performTests');

const label = 'network-02-simple-tls';

describe(label, () => {
  performTests(label, 'fabrikkaConfig-1org-1channel-1chaincode-tls.json');
});
