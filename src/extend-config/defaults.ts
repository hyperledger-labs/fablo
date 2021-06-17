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
  ca: {
    prefix: "ca",
  },
  peer: {
    prefix: "peer",
    db: "LevelDb",
    anchorPeerInstances: 1,
  },
  chaincodeEndorsement(orgs: OrgConfig[], capabilities: Capabilities): string | undefined {
    return capabilities.isV2 ? undefined : `AND (${orgs.map((o) => `'${o.mspName}.member'`).join(", ")})`;
  },
};
