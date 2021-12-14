import { FabloConfigJson } from "../types/FabloConfigJson";
import { FabloConfigExtended } from "../types/FabloConfigExtended";
import { extendOrgsConfig } from "./extendOrgsConfig";
import extendNetworkSettings from "./extendNetworkSettings";
import extendChannelsConfig from "./extendChannelsConfig";
import extendChaincodesConfig from "./extendChaincodesConfig";
import extendHooksConfig from "./extendHooksConfig";
import { distinctOrdererHeads, mergeOrdererGroups } from "./mergeOrdererGroups";

const extendConfig = (json: FabloConfigJson): FabloConfigExtended => {
  const {
    global: networkSettingsJson,
    orgs: orgsJson,
    channels: channelsJson,
    chaincodes: chaincodesJson,
    hooks: hooksJson,
  } = json;

  const global = extendNetworkSettings(networkSettingsJson);
  const orgs = extendOrgsConfig(orgsJson, global);
  const ordererGroups = mergeOrdererGroups(orgs);
  const orderedHeadsDistinct = distinctOrdererHeads(ordererGroups);

  const channels = extendChannelsConfig(channelsJson, orgs, ordererGroups);
  const chaincodes = extendChaincodesConfig(chaincodesJson, channels, global);
  const hooks = extendHooksConfig(hooksJson);

  return {
    global,
    ordererGroups,
    orderedHeadsDistinct,
    orgs,
    channels,
    chaincodes,
    hooks,
  };
};

export default extendConfig;
