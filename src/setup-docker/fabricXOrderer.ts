import { FabloConfigExtended } from "../types/FabloConfigExtended";

export type FabricXOrdererRole = "router" | "batcher" | "consenter" | "assembler";

export interface FabricXOrdererNode {
  role: FabricXOrdererRole;
  host: string;
  command: string;
  port: number;
  cryptoName: string;
  cryptoDir: string;
  dataDir: string;
  configFile: string;
  shardId?: number;
}

export interface FabricXOrdererParty {
  partyId: number;
  org: FabricXOrdererOrg;
  slug: string;
  endpointId: number;
  router: FabricXOrdererNode;
  batchers: FabricXOrdererNode[];
  consenter: FabricXOrdererNode;
  assembler: FabricXOrdererNode;
}

export interface FabricXOrdererOrg {
  name: string;
  domain: string;
  mspId: string;
}

export interface FabricXOrderer {
  parties: FabricXOrdererParty[];
  faultTolerance: "CFT" | "BFT";
}
export const SUPPORTED_ORDERER_PARTY_COUNTS = [1, 4];

const HOST_PREFIX = "orderer";
const FIRST_PORT = 7050;
const PORT_STEP_PER_PARTY = 100;

const ROLE_PORT_OFFSET: Record<FabricXOrdererRole, number> = {
  router: 0,
  batcher: 1,
  consenter: 2,
  assembler: 3,
};

const ROLE_COMMAND: Record<FabricXOrdererRole, string> = {
  router: "router",
  batcher: "batcher",
  consenter: "consensus",
  assembler: "assembler",
};

const buildNode = (
  party: { partyId: number; slug: string; org: FabricXOrdererOrg },
  hostPrefix: string,
  role: FabricXOrdererRole,
  cryptoName: string,
  shardId?: number,
): FabricXOrdererNode => ({
  role,
  host: `${hostPrefix}-${role}`,
  command: ROLE_COMMAND[role],
  port: FIRST_PORT + (party.partyId - 1) * PORT_STEP_PER_PARTY + ROLE_PORT_OFFSET[role],
  cryptoName,
  cryptoDir: `ordererOrganizations/${party.org.domain}/orderers/${party.slug}/${cryptoName}.${party.org.domain}`,
  dataDir: `data/orderers/${party.slug}-${role}`,
  configFile: `config/${party.slug}-${role}.yaml`,
  ...(shardId === undefined ? {} : { shardId }),
});

const buildParty = (partyId: number, partyCount: number): FabricXOrdererParty => {
  const single = partyCount === 1;
  const org: FabricXOrdererOrg = single
    ? { name: "Orderer", domain: "orderer.example.com", mspId: "OrdererOrdererMSP" }
    : { name: `orderer-org-${partyId}`, domain: `orderer-org-${partyId}`, mspId: `OrdererOrg${partyId}MSP` };
  const party = { partyId, slug: `party${partyId}`, org };
  const hostPrefix = single ? HOST_PREFIX : `${HOST_PREFIX}-${party.slug}`;
  return {
    ...party,
    endpointId: partyId - 1,
    router: buildNode(party, hostPrefix, "router", "router"),
    batchers: [buildNode(party, hostPrefix, "batcher", "batcher1", 1)],
    consenter: buildNode(party, hostPrefix, "consenter", "consenter"),
    assembler: buildNode(party, hostPrefix, "assembler", "assembler"),
  };
};

export const buildFabricXOrderer = (partyCount: number): FabricXOrderer => {
  if (!SUPPORTED_ORDERER_PARTY_COUNTS.includes(partyCount)) {
    throw new Error(
      `Fabric-X orderer supports ${SUPPORTED_ORDERER_PARTY_COUNTS.join(
        " or ",
      )} parties, but ${partyCount} were requested.`,
    );
  }
  const parties = Array.from({ length: partyCount }, (_, i) => buildParty(i + 1, partyCount));
  return { parties, faultTolerance: partyCount === 1 ? "CFT" : "BFT" };
};

export const getOrdererPartyCount = (configExtended: FabloConfigExtended): number =>
  configExtended.ordererGroups[0]?.orderers.length ?? 1;
