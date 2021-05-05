export default {
  networkSettings: {
    monitoring: {
      loglevel: "info",
    },
  },
  organization: {
    mspName: (name: string): string => `${name}MSP`,
  },
  ca: {
    prefix: "ca",
  },
  peer: {
    prefix: "peer",
    db: "LevelDb",
    anchorPeerInstances: 1,
  },
};
