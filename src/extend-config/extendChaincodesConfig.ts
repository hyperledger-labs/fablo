import { ChaincodeJson } from "../types/FabloConfigJson";
import { ChaincodeConfig, ChannelConfig, Global, PrivateCollectionConfig } from "../types/FabloConfigExtended";
import defaults from "./defaults";
import { version } from "../repositoryUtils";

const createPrivateCollectionConfig = (
  fabricVersion: string,
  channel: ChannelConfig,
  name: string,
  collectionOrgNames: string[],
): PrivateCollectionConfig => {
  // Organizations that will host the actual data
  const collectionOrgs = (channel.orgs || []).filter((o) => !!collectionOrgNames.find((n) => n === o.name));
  if (collectionOrgs.length < collectionOrgNames.length) {
    throw new Error(`Cannot find all orgs for names ${collectionOrgNames}`);
  }
  const policy = `OR(${collectionOrgs.map((o) => `'${o.mspName}.member'`).join(",")})`;

  // We need to know the number of anchor peers per org in a channel to determine the following parameters:
  //  - maxPeerCount -> all peers
  //  - requiredPeerCount -> minimal number of anchor peers from one organization in a channel
  const anchorPeerCountsInChannel = channel.orgs.map((o) => (o.anchorPeers || []).length);
  const maxPeerCount = anchorPeerCountsInChannel.reduce((a, b) => a + b, 0);
  const requiredPeerCount = anchorPeerCountsInChannel.reduce((a, b) => Math.min(a, b), maxPeerCount) || 1;

  const memberOnlyRead = version(fabricVersion).isGreaterOrEqual("1.4.0") ? { memberOnlyRead: true } : {};
  const memberOnlyWrite = version(fabricVersion).isGreaterOrEqual("2.0.0") ? { memberOnlyWrite: true } : {};

  return {
    name,
    policy,
    requiredPeerCount,
    maxPeerCount,
    blockToLive: 0,
    ...memberOnlyRead,
    ...memberOnlyWrite,
  };
};

const extendChaincodesConfig = (
  chaincodes: ChaincodeJson[],
  transformedChannels: ChannelConfig[],
  network: Global,
): ChaincodeConfig[] => {
  return chaincodes.map((chaincode) => {
    const channel = transformedChannels.find((c) => c.name === chaincode.channel);
    if (!channel) throw new Error(`No matching channel with name '${chaincode.channel}'`);

    const initParams: { initRequired: boolean } | { init: string } = network.capabilities.isV2
      ? { initRequired: chaincode.initRequired || defaults.chaincode.initRequired }
      : { init: chaincode.init || defaults.chaincode.init };

    const endorsement = chaincode.endorsement ?? defaults.chaincode.endorsement(channel.orgs, network.capabilities);

    const privateData = (chaincode.privateData ?? []).map((d) =>
      createPrivateCollectionConfig(network.fabricVersion, channel, d.name, d.orgNames),
    );
    const privateDataConfigFile = privateData.length > 0 ? `collections/${chaincode.name}.json` : undefined;

    return {
      directory: chaincode.directory,
      name: chaincode.name,
      version: chaincode.version,
      lang: chaincode.lang,
      channel,
      ...initParams,
      endorsement,
      instantiatingOrg: channel.instantiatingOrg,
      privateDataConfigFile,
      privateData,
    };
  });
};

export default extendChaincodesConfig;
