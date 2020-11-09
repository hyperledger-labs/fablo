const { performTests } = require('./performTests');

const label = 'network-04-simple-2chaincodes';

describe(label, () => {
  performTests(label, 'fabrikkaConfig-1org-1channel-2chaincodes.json');
});
