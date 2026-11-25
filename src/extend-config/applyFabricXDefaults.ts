import { FabloConfigJson, FabricXConfigJson } from "../types/FabloConfigJson";
import defaults from "./defaults";

export const isFabricXConfig = (json: FabloConfigJson | FabricXConfigJson): json is FabricXConfigJson =>
  json.global.provider === "fabric-x";

const applyFabricXDefaults = (config: FabloConfigJson | FabricXConfigJson): FabloConfigJson => {
  if (!isFabricXConfig(config)) return config;

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