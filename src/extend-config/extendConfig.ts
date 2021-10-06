import { FabloConfigJson } from "../types/FabloConfigJson";
import { FabloConfigExtended } from "../types/FabloConfigExtended";
import { extendRootOrgConfig, extendOrgsConfig } from "./extendOrgsConfig";
import extendNetworkSettings from "./extendNetworkSettings";
import extendChannelsConfig from "./extendChannelsConfig";
import extendChaincodesConfig from "./extendChaincodesConfig";

const extendConfig = (json: FabloConfigJson): FabloConfigExtended => {
  const {
    networkSettings: networkSettingsJson,
    rootOrg: rootOrgJson,
    orgs: orgsJson,
    channels: channelsJson,
    chaincodes: chaincodesJson,
  } = json;

  const networkSettings = extendNetworkSettings(networkSettingsJson);
  const rootOrg = extendRootOrgConfig(rootOrgJson);
  const orgs = extendOrgsConfig(orgsJson, networkSettings);
  const channels = extendChannelsConfig(channelsJson, orgs);
  const chaincodes = extendChaincodesConfig(chaincodesJson, channels, networkSettings);

  return {
    networkSettings,
    rootOrg,
    orgs,
    channels,
    chaincodes,
  };
};

export default extendConfig;
