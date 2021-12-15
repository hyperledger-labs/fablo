import { OrgConfig } from "./FabloConfigExtended";

interface ExplorerConfig {
  "network-configs": { [name: string]: NetworkConfig };
  license: string;
}

interface NetworkConfig {
  name: string;
  profile: string;
}

export function createExplorerConfig(orgs: OrgConfig[]): ExplorerConfig {
  const networkConfigs: { [name: string]: NetworkConfig } = {};
  orgs.forEach((o) => {
    const orgName = o.name.toLowerCase();
    networkConfigs[`network-${orgName}`] = {
      name: `Network of ${o.name}`,
      profile: `/opt/explorer/app/platform/fabric/connection-profile/connection-profile-${orgName}.json`,
    };
  });
  return {
    "network-configs": networkConfigs,
    license: "Apache-2.0",
  };
}
