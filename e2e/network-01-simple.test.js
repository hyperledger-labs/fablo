const { performTests } = require('./performTests');

const label = 'network-01-simple';

describe(label, () => {
  performTests(label, 'fabrikkaConfig-1org-1channel-1chaincode.json');
});
