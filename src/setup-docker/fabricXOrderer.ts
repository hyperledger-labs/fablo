import { FabloConfigExtended } from "../types/FabloConfigExtended";

export type FabricXOrdererRole = "router" | "batcher" | "consenter" | "assembler";

/** One Arma process, for example the router of party 1. */
export interface FabricXOrdererNode {
  role: FabricXOrdererRole;
  /** Compose service name, container name and DNS name on the Docker network, for example orderer-router. */
  host: string;
  /** Sub command of the orderer binary that starts this node. */
  command: string;
  /** Port the node listens on. */
  port: number;
  /** Node name in crypto-config.yaml, for example router or batcher1. */
  cryptoName: string;
  /** Folder of the node in the generated crypto material, relative to the crypto folder. */
  cryptoDir: string;
  /** Data folder, relative to the fabric-x output folder. */
  dataDir: string;
  /** Node config file, relative to the fabric-x output folder. */
  configFile: string;
  /** Only set for batchers. */
  shardId?: number;
}

export interface FabricXOrdererParty {
  partyId: number;
  /** Folder and file name part of the party, for example party1. */
  slug: string;
  /** Number used in the OrdererEndpoints entries of configtx.yaml. It starts at 0. */
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
  org: FabricXOrdererOrg;
  parties: FabricXOrdererParty[];
}

/** Number of orderer parties the generator can render today. */
export const SUPPORTED_ORDERER_PARTIES = 1;

const ORDERER_ORG: FabricXOrdererOrg = {
  name: "Orderer",
  domain: "orderer.example.com",
  mspId: "OrdererOrdererMSP",
};

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
  party: { partyId: number; slug: string },
  role: FabricXOrdererRole,
  cryptoName: string,
  shardId?: number,
): FabricXOrdererNode => ({
  role,
  // Host names have no party number yet. Naming for more than one party is decided together with multi-party support.
  host: `${HOST_PREFIX}-${role}`,
  command: ROLE_COMMAND[role],
  port: FIRST_PORT + (party.partyId - 1) * PORT_STEP_PER_PARTY + ROLE_PORT_OFFSET[role],
  cryptoName,
  cryptoDir: `ordererOrganizations/${ORDERER_ORG.domain}/orderers/${party.slug}/${cryptoName}.${ORDERER_ORG.domain}`,
  dataDir: `data/orderers/${party.slug}-${role}`,
  configFile: `config/${party.slug}-${role}.yaml`,
  ...(shardId === undefined ? {} : { shardId }),
});

const buildParty = (partyId: number): FabricXOrdererParty => {
  const party = { partyId, slug: `party${partyId}` };
  return {
    ...party,
    endpointId: partyId - 1,
    router: buildNode(party, "router", "router"),
    batchers: [buildNode(party, "batcher", "batcher1", 1)],
    consenter: buildNode(party, "consenter", "consenter"),
    assembler: buildNode(party, "assembler", "assembler"),
  };
};

export const buildFabricXOrderer = (partyCount: number): FabricXOrderer => {
  if (!Number.isInteger(partyCount) || partyCount !== SUPPORTED_ORDERER_PARTIES) {
    throw new Error(
      `Fabric-X orderer supports ${SUPPORTED_ORDERER_PARTIES} party for now, but ${partyCount} were requested.`,
    );
  }
  const parties = Array.from({ length: partyCount }, (_, i) => buildParty(i + 1));
  return { org: ORDERER_ORG, parties };
};

/** The orderer group of a Fabric-X network has one orderer per party. */
export const getOrdererPartyCount = (configExtended: FabloConfigExtended): number =>
  configExtended.ordererGroups[0]?.orderers.length ?? SUPPORTED_ORDERER_PARTIES;
