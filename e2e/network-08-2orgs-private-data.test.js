const { performTests } = require('./performTests');

const label = 'network-08-2orgs-private-data';

describe(label, () => {
  performTests(label, 'fabricaConfig-2orgs-private-data-2chaincodes.json');
});
