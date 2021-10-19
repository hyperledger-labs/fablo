import { ChannelConfig, OrdererOrgConfig, OrgConfig } from "../types/FabloConfigExtended";
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
  ordererOrgs: OrdererOrgConfig[],
): ChannelConfig => {
  const channelName = channelJsonFormat.name;
  const profileName = _.chain(channelName).camelCase().upperFirst().value();
  const ordererOrgName = channelJsonFormat.ordererOrg ?? defaults.channel.ordererOrg(ordererOrgs);

  const orgNames = channelJsonFormat.orgs.map((o) => o.name);
  const orgPeers = channelJsonFormat.orgs.map((o) => o.peers).reduce((a, b) => a.concat(b), []);
  const orgsForChannel = orgsTransformed
    .filter((org) => orgNames.includes(org.name))
    .map((org) => filterToAvailablePeers(org, orgPeers));

  const ordererHead = ordererOrgs.filter((org) => org.name == ordererOrgName)[0].ordererHead;

  return {
    name: channelName,
    orgs: orgsForChannel,
    ordererHead,
    profileName,
    instantiatingOrg: orgsForChannel[0],
  };
};

const extendChannelsConfig = (
  channelsJsonConfigFormat: ChannelJson[],
  orgsTransformed: OrgConfig[],
  ordererOrgs: OrdererOrgConfig[],
): ChannelConfig[] => channelsJsonConfigFormat.map((ch) => extendChannelConfig(ch, orgsTransformed, ordererOrgs));

export default extendChannelsConfig;
