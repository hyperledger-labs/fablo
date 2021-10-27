import { FabloConfigJson } from "../types/FabloConfigJson";
import { FabloConfigExtended, OrdererGroup, OrdererOrgConfig, OrgConfig } from "../types/FabloConfigExtended";
import { extendOrdererOrgsConfig, extendOrgsConfig } from "./extendOrgsConfig";
import extendNetworkSettings from "./extendNetworkSettings";
import extendChannelsConfig from "./extendChannelsConfig";
import extendChaincodesConfig from "./extendChaincodesConfig";
import _ = require("lodash");

const mergeOrdererGroupsByName = (ordererOrgs: OrdererOrgConfig[], orgs: OrgConfig[]): OrdererGroup[] => {
  const orderersOrdererOrgs = ordererOrgs.flatMap((o) => o.ordererGroups);
  const orderersOrgs = orgs.flatMap((o) => o.ordererGroups);

  const allOrdererGroups = orderersOrdererOrgs.concat(orderersOrgs);
  const grouped: Record<string, OrdererGroup[]> = _.groupBy(allOrdererGroups, (group) => group.name);

  return Object.values(grouped).flatMap((groupsWithSameGroupName) => {
    const orderers = groupsWithSameGroupName.flatMap((group) => group.orderers);
    const hostingOrgs = groupsWithSameGroupName.flatMap((group) => group.hostingOrgs);

    return {
      ...groupsWithSameGroupName[0],
      hostingOrgs,
      orderers,
      ordererHead: orderers[0],
    };
  });
};

const extendConfig = (json: FabloConfigJson): FabloConfigExtended => {
  const {
    networkSettings: networkSettingsJson,
    ordererOrgs: ordererOrgsJson,
    orgs: orgsJson,
    channels: channelsJson,
    chaincodes: chaincodesJson,
  } = json;

  const networkSettings = extendNetworkSettings(networkSettingsJson);
  const ordererOrgs = extendOrdererOrgsConfig(ordererOrgsJson);
  const orgs = extendOrgsConfig(orgsJson, networkSettings);
  const ordererGroups = mergeOrdererGroupsByName(ordererOrgs, orgs);

  const channels = extendChannelsConfig(channelsJson, orgs, ordererGroups);
  const chaincodes = extendChaincodesConfig(chaincodesJson, channels, networkSettings);

  return {
    networkSettings,
    ordererOrgHead: ordererOrgs[0],
    ordererOrgs,
    orgs,
    channels,
    chaincodes,
    ordererGroups,
  };
};

export default extendConfig;
