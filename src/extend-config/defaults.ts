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
    db: "sqlite" as const,
  },
  peer: {
    prefix: "peer",
    db: "LevelDb",
    anchorPeerInstances: (peerCount: number): number => peerCount,
  },
  channel: {
    ordererGroup: (ordererGroups: OrdererGroup[]): string | undefined => ordererGroups[0]?.name,
  },
  chaincode: {
    init: '{"Args":[]}',
    initRequired: false,
    endorsement(orgs: OrgConfig[], capabilities: Capabilities): string | undefined {
      return capabilities.isV2 ? undefined : `AND (${orgs.map((o) => `'${o.mspName}.member'`).join(", ")})`;
    },
  },
  namespace: {
    policy(orgs: OrgConfig[]): string {
      return `AND(${orgs.map((o) => `'${o.mspName}.member'`).join(",")})`;
    },
  },
  fabricX: {
    fabricVersion: "3.1.0",
    orderer: {
      partyCount: 1,
      organization(partyId: number, partyCount: number): { name: string; domain: string; mspName: string } {
        return partyCount === 1
          ? { name: "Orderer", domain: "orderer.example.com", mspName: "OrdererOrdererMSP" }
          : { name: `OrdererOrg${partyId}`, domain: `orderer-org-${partyId}`, mspName: `OrdererOrg${partyId}MSP` };
      },
    },
  },
};
