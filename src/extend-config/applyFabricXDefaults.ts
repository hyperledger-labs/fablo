import { FabloConfigJson, FabricXConfigJson } from "../types/FabloConfigJson";
import defaults from "./defaults";

// Fills in the values that a compact fabric-x config leaves out, so the rest of Fablo sees the full config.
const applyFabricXDefaults = (json: FabloConfigJson | FabricXConfigJson): FabloConfigJson => {
  if (json.global?.provider !== "fabric-x") return json as FabloConfigJson;

  const config = json as FabricXConfigJson;
  const orgs = config.orgs.map((org) => ({
    ...org,
    organization: {
      ...org.organization,
      mspName: org.organization.mspName ?? defaults.organization.mspName(org.organization.name),
    },
    ca: org.ca ?? { prefix: defaults.ca.prefix, db: defaults.ca.db },
  }));
  const channels = config.channels.map((channel) => {
    const channelOrgs: { name: string; peers?: string[] }[] =
      channel.orgs ?? orgs.map((org) => ({ name: org.organization.name }));
    return { ...channel, orgs: channelOrgs.map((org) => ({ name: org.name, peers: org.peers ?? [] })) };
  });

  return {
    ...config,
    global: {
      fabricVersion: defaults.fabricX.fabricVersion,
      tls: true,
      peerDevMode: false,
      ...config.global,
    },
    orgs,
    channels,
    chaincodes: config.chaincodes ?? [],
    hooks: config.hooks ?? {},
  };
};

export default applyFabricXDefaults;
