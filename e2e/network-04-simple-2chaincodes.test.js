const { performTests } = require('./performTests');

const label = 'network-04-simple-2chaincodes';

describe(label, () => {
  performTests(label, 'fabricaConfig-1org-1channel-2chaincodes.json');
});
