module.exports = {
  networkSettings: {
    monitoring: {
      loglevel: 'info',
    },
  },
  organization: {
    mspName: (name) => `${name}MSP`,
  },
  ca: {
    prefix: 'ca',
  },
  peer: {
    prefix: 'peer',
    db: 'LevelDb',
    anchorPeerInstances: 1,
  },
};
