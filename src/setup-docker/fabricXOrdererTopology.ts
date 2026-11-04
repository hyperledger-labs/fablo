import { FabricXOrdererPartyConfig } from "../types/FabloConfigExtended";
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
  acceptsClients: boolean;
  dependsOn: string[];
  shardId?: number;
}
export interface FabricXOrdererOrg {
  name: string;
  domain: string;
  mspName: string;
}
export interface FabricXOrdererParty {
  partyId: number;
  slug: string;
  org: FabricXOrdererOrg;
  endpointId: number;
  router: FabricXOrdererNode;
  batchers: FabricXOrdererNode[];
  consenter: FabricXOrdererNode;
  assembler: FabricXOrdererNode;
  nodes: FabricXOrdererNode[];
}
export interface FabricXOrdererTopology {
  parties: FabricXOrdererParty[];
  faultTolerance: "CFT" | "BFT";
  routerHosts: string[];
}
export const SUPPORTED_ORDERER_PARTY_COUNTS = [1, 4];
const HOST_PREFIX = "orderer";
const FIRST_PORT = 7050;
const PORT_STEP_PER_PARTY = 100;
const ROLE_PORT_OFFSET: Record<FabricXOrdererRole, number> = { router: 0, batcher: 1, consenter: 2, assembler: 3 };
const ROLE_COMMAND: Record<FabricXOrdererRole, string> = {
  router: "router",
  batcher: "batcher",
  consenter: "consensus",
  assembler: "assembler",
};
const ROLES_WITH_CLIENTS: FabricXOrdererRole[] = ["router", "assembler"];

const hostPrefixOf = (partyId: number, partyCount: number): string =>
  partyCount === 1 ? HOST_PREFIX : `${HOST_PREFIX}-party${partyId}`;

const hostOf = (hostPrefix: string, role: FabricXOrdererRole): string => `${hostPrefix}-${role}`;

const buildNode = (
  party: { partyId: number; slug: string; org: FabricXOrdererOrg },
  hostPrefix: string,
  role: FabricXOrdererRole,
  cryptoName: string,
  dependsOn: string[],
  shardId?: number,
): FabricXOrdererNode => ({
  role,
  host: hostOf(hostPrefix, role),
  command: ROLE_COMMAND[role],
  port: FIRST_PORT + (party.partyId - 1) * PORT_STEP_PER_PARTY + ROLE_PORT_OFFSET[role],
  cryptoName,
  cryptoDir: `ordererOrganizations/${party.org.domain}/orderers/${party.slug}/${cryptoName}.${party.org.domain}`,
  dataDir: `data/orderers/${party.slug}-${role}`,
  configFile: `config/${hostPrefix}-${role}.yaml`,
  acceptsClients: ROLES_WITH_CLIENTS.includes(role),
  dependsOn,
  ...(shardId === undefined ? {} : { shardId }),
});

const buildParty = (
  partyId: number,
  partyCount: number,
  config: FabricXOrdererPartyConfig,
  consenterHosts: string[],
): FabricXOrdererParty => {
  const { name, domain, mspName } = config.organization;
  const party = { partyId, slug: `party${partyId}`, org: { name, domain, mspName } };
  const hostPrefix = hostPrefixOf(partyId, partyCount);

  const batchers = [buildNode(party, hostPrefix, "batcher", "batcher1", consenterHosts, 1)];
  const consenter = buildNode(party, hostPrefix, "consenter", "consenter", []);
  const assembler = buildNode(
    party,
    hostPrefix,
    "assembler",
    "assembler",
    batchers.map((batcher) => batcher.host),
  );
  const router = buildNode(party, hostPrefix, "router", "router", [assembler.host]);

  return {
    ...party,
    endpointId: partyId - 1,
    router,
    batchers,
    consenter,
    assembler,
    nodes: [router, ...batchers, consenter, assembler],
  };
};

export const buildFabricXOrdererTopology = (partyConfigs: FabricXOrdererPartyConfig[]): FabricXOrdererTopology => {
  const partyCount = partyConfigs.length;
  if (!SUPPORTED_ORDERER_PARTY_COUNTS.includes(partyCount)) {
    throw new Error(
      `Fablo currently supports ${SUPPORTED_ORDERER_PARTY_COUNTS.join(
        " or ",
      )} Fabric-X orderer parties, but ${partyCount} were configured.`,
    );
  }

  const consenterHosts = partyConfigs.map((_, i) => hostOf(hostPrefixOf(i + 1, partyCount), "consenter"));
  const parties = partyConfigs.map((config, i) => buildParty(i + 1, partyCount, config, consenterHosts));

  return {
    parties,
    faultTolerance: partyCount === 1 ? "CFT" : "BFT",
    routerHosts: parties.map((party) => party.router.host),
  };
};
