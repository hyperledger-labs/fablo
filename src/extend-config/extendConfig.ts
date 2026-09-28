import { FabloConfigJson } from "../types/FabloConfigJson";
import { FabloConfigExtended } from "../types/FabloConfigExtended";
import { extendOrgsConfig } from "./extendOrgsConfig";
import extendGlobal from "./extendGlobal";
import extendChannelsConfig from "./extendChannelsConfig";
import extendChaincodesConfig, { checkUniqueChaincodeNames } from "./extendChaincodesConfig";
import extendHooksConfig from "./extendHooksConfig";
import { distinctOrdererHeads, mergeOrdererGroups } from "./mergeOrdererGroups";
import extendNamespacesConfig from "./extendNamespacesConfig";
const extendConfig = (json: FabloConfigJson): FabloConfigExtended => {
  const {
    global: globalJson,
    orgs: orgsJson,
    channels: channelsJson,
    chaincodes: chaincodesJson,
    hooks: hooksJson,
    namespaces: namespacesJson,
  } = json;

  const global = extendGlobal(globalJson);
  const orgs = extendOrgsConfig(orgsJson, global);
  const ordererGroups = mergeOrdererGroups(orgs);
  const orderedHeadsDistinct = distinctOrdererHeads(ordererGroups);

  const channels = extendChannelsConfig(channelsJson, orgs, ordererGroups);
  checkUniqueChaincodeNames(chaincodesJson);
  const chaincodes = extendChaincodesConfig(chaincodesJson, channels, global);
  const hooks = extendHooksConfig(hooksJson);
  const namespaces = global.provider === "fabric-x" ? extendNamespacesConfig(namespacesJson ?? [], channels[0]?.orgs ?? []) : [];
  return {
    global,
    ordererGroups,
    orderedHeadsDistinct,
    orgs,
    channels,
    chaincodes,
    hooks,
    namespaces,
  };
};

export default extendConfig;
