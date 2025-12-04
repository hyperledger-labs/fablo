import { OrdererConfig, OrdererGroup, OrgConfig } from "../types/FabloConfigExtended";
import * as _ from "lodash";

export const mergeOrdererGroups = (orgs: OrgConfig[]): OrdererGroup[] => {
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

export const distinctOrdererHeads = (ordererGroups: OrdererGroup[]): OrdererConfig[] => {
  const allOrdererHeads = ordererGroups.flatMap((g) => g.ordererHeads);
  return _.unionBy(allOrdererHeads, (o) => o.domain);
};
