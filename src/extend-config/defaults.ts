import { Capabilities, OrgConfig } from "../types/FabricaConfigExtended";

export default {
  networkSettings: {
    monitoring: {
      loglevel: "info",
    },
  },
  organization: {
    mspName: (name: string): string => `${name}MSP`,
  },
  orderer: {
    prefix: "orderer",
  },
  ca: {
    prefix: "ca",
  },
  peer: {
    prefix: "peer",
    db: "LevelDb",
    anchorPeerInstances: 1,
  },
  chaincode: {
    init: '{"Args":[]}',
    initRequired: false,
    endorsement(orgs: OrgConfig[], capabilities: Capabilities): string | undefined {
      return capabilities.isV2 ? undefined : `AND (${orgs.map((o) => `'${o.mspName}.member'`).join(", ")})`;
    },
  },
};
