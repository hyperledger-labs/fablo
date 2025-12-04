import { Capabilities, OrdererGroup, OrgConfig } from "../types/FabloConfigExtended";

export default {
  global: {
    monitoring: {
      loglevel: "info",
    },
    tools: {
      explorer: false,
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
    db: "sqlite",
  },
  peer: {
    prefix: "peer",
    db: "LevelDb",
    anchorPeerInstances: (peerCount: number): number => peerCount,
  },
  channel: {
    ordererGroup: (ordererGroups: OrdererGroup[]): string => ordererGroups[0].name,
  },
  chaincode: {
    init: '{"Args":[]}',
    initRequired: false,
    endorsement(orgs: OrgConfig[], capabilities: Capabilities): string | undefined {
      return capabilities.isV2 ? undefined : `AND (${orgs.map((o) => `'${o.mspName}.member'`).join(", ")})`;
    },
  },
};
