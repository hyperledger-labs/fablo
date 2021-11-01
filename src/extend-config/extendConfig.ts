import * as _ from "lodash";
import { FabloConfigJson } from "../types/FabloConfigJson";
import { FabloConfigExtended, OrdererGroup, OrgConfig } from "../types/FabloConfigExtended";
import { extendOrgsConfig } from "./extendOrgsConfig";
import extendNetworkSettings from "./extendNetworkSettings";
import extendChannelsConfig from "./extendChannelsConfig";
import extendChaincodesConfig from "./extendChaincodesConfig";
import extendHooksConfig from "./extendHooksConfig";

// TODO
const mergeOrdererGroupsByName = (orgs: OrgConfig[]): OrdererGroup[] => {
  const ordererGroups = orgs.flatMap((o) => o.ordererGroups);

  const ordererGroupsGrouped: Record<string, OrdererGroup[]> = _.groupBy(ordererGroups, (group) => group.name);

  return Object.values(ordererGroupsGrouped).flatMap((groupsWithSameGroupName) => {
    const orderers = groupsWithSameGroupName.flatMap((group) => group.orderers);
    const hostingOrgs = groupsWithSameGroupName.flatMap((group) => group.hostingOrgs);
    const ordererHeads = groupsWithSameGroupName.flatMap((group) => group.ordererHeads);

    return {
      ...groupsWithSameGroupName[0],
      hostingOrgs,
      orderers,
      ordererHeads,
      ordererHead: ordererHeads[0],
    };
  });
};

const extendConfig = (json: FabloConfigJson): FabloConfigExtended => {
  const {
    networkSettings: networkSettingsJson,
    orgs: orgsJson,
    channels: channelsJson,
    chaincodes: chaincodesJson,
    hooks: hooksJson,
  } = json;

  const networkSettings = extendNetworkSettings(networkSettingsJson);
  const orgs = extendOrgsConfig(orgsJson, networkSettings);
  const ordererGroups = mergeOrdererGroupsByName(orgs);

  const channels = extendChannelsConfig(channelsJson, orgs, ordererGroups);
  const chaincodes = extendChaincodesConfig(chaincodesJson, channels, networkSettings);
  const hooks = extendHooksConfig(hooksJson);

  return {
    networkSettings,
    ordererGroups,
    orgs,
    channels,
    chaincodes,
    hooks,
  };
};

export default extendConfig;
