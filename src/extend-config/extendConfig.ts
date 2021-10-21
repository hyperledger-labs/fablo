import { FabloConfigJson } from "../types/FabloConfigJson";
import { FabloConfigExtended } from "../types/FabloConfigExtended";
import { extendOrgsConfig, extendRootOrgConfig } from "./extendOrgsConfig";
import extendNetworkSettings from "./extendNetworkSettings";
import extendChannelsConfig from "./extendChannelsConfig";
import extendChaincodesConfig from "./extendChaincodesConfig";
import extendHooksConfig from "./extendHooksConfig";

const extendConfig = (json: FabloConfigJson): FabloConfigExtended => {
  const {
    networkSettings: networkSettingsJson,
    rootOrg: rootOrgJson,
    orgs: orgsJson,
    channels: channelsJson,
    chaincodes: chaincodesJson,
    hooks: hooksJson,
  } = json;

  const networkSettings = extendNetworkSettings(networkSettingsJson);
  const rootOrg = extendRootOrgConfig(rootOrgJson);
  const orgs = extendOrgsConfig(orgsJson, networkSettings);
  const channels = extendChannelsConfig(channelsJson, orgs);
  const chaincodes = extendChaincodesConfig(chaincodesJson, channels, networkSettings);
  const hooks = extendHooksConfig(hooksJson);

  return {
    networkSettings,
    rootOrg,
    orgs,
    channels,
    chaincodes,
    hooks,
  };
};

export default extendConfig;
