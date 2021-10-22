import { FabloConfigJson } from "../types/FabloConfigJson";
import { FabloConfigExtended } from "../types/FabloConfigExtended";
import { extendRootOrgConfig, extendOrdererOrgsConfig, extendOrgsConfig } from "./extendOrgsConfig";
import extendNetworkSettings from "./extendNetworkSettings";
import extendChannelsConfig from "./extendChannelsConfig";
import extendChaincodesConfig from "./extendChaincodesConfig";

const extendConfig = (json: FabloConfigJson): FabloConfigExtended => {
  const {
    networkSettings: networkSettingsJson,
    rootOrg: rootOrgJson,
    ordererOrgs: ordererOrgsJson,
    orgs: orgsJson,
    channels: channelsJson,
    chaincodes: chaincodesJson,
  } = json;

  const networkSettings = extendNetworkSettings(networkSettingsJson);
  const rootOrg = extendRootOrgConfig(rootOrgJson);
  const ordererOrgs = extendOrdererOrgsConfig(ordererOrgsJson);
  const orgs = extendOrgsConfig(orgsJson, networkSettings);
  const channels = extendChannelsConfig(channelsJson, orgs, ordererOrgs);
  const chaincodes = extendChaincodesConfig(chaincodesJson, channels, networkSettings);

  return {
    networkSettings,
    rootOrg,
    ordererOrgHead: ordererOrgs[0],
    ordererOrgs,
    orgs,
    channels,
    chaincodes,
  };
};

export default extendConfig;
