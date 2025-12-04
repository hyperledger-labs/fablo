import { ChannelConfig, OrdererGroup, OrgConfig } from "../types/FabloConfigExtended";
import { ChannelJson } from "../types/FabloConfigJson";
import * as _ from "lodash";
import defaults from "./defaults";

const filterToAvailablePeers = (orgTransformedFormat: OrgConfig, peersTransformedFormat: string[]) => {
  const filteredPeers = orgTransformedFormat.peers.filter((p) => peersTransformedFormat.includes(p.name));
  return {
    ...orgTransformedFormat,
    peers: filteredPeers,
    headPeer: filteredPeers[0],
  };
};

const extendChannelConfig = (
  channelJsonFormat: ChannelJson,
  orgsTransformed: OrgConfig[],
  ordererGroups: OrdererGroup[],
): ChannelConfig => {
  const channelName = channelJsonFormat.name;
  const profileName = _.chain(channelName).camelCase().upperFirst().value();
  const ordererGroupName = channelJsonFormat.ordererGroup ?? defaults.channel.ordererGroup(ordererGroups);

  const orgNames = channelJsonFormat.orgs.map((o) => o.name);
  const orgPeers = channelJsonFormat.orgs.map((o) => o.peers).reduce((a, b) => a.concat(b), []);
  const orgsForChannel = orgsTransformed
    .filter((org) => orgNames.includes(org.name))
    .map((org) => filterToAvailablePeers(org, orgPeers));

  const ordererGroup = ordererGroups.filter((group) => group.name == ordererGroupName)[0];
  const ordererHead = ordererGroup.ordererHeads[0];

  return {
    name: channelName,
    profileName,
    orgs: orgsForChannel,
    ordererGroup,
    ordererHead,
    instantiatingOrg: orgsForChannel[0],
  };
};

const extendChannelsConfig = (
  channelsJsonConfigFormat: ChannelJson[],
  orgsTransformed: OrgConfig[],
  ordererGroups: OrdererGroup[],
): ChannelConfig[] => channelsJsonConfigFormat.map((ch) => extendChannelConfig(ch, orgsTransformed, ordererGroups));

export default extendChannelsConfig;
