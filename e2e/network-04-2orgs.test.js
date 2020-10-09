const { performTests } = require('./performTests');

const label = 'network-04-2orgs';

describe(label, () => {
  performTests(label, 'fabrikkaConfig-2orgs-2channels-1chaincode.json');
});
