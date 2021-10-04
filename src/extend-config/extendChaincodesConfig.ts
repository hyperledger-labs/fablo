import { ChaincodeJson } from "../types/FabloConfigJson";
import { ChaincodeConfig, ChannelConfig, NetworkSettings, PrivateCollectionConfig } from "../types/FabloConfigExtended";
import defaults from "./defaults";
import { version } from "../repositoryUtils";

const createPrivateCollectionConfig = (
  fabricVersion: string,
  channel: ChannelConfig,
  name: string,
  orgNames: string[],
): PrivateCollectionConfig => {
  // We need only orgs that can have access to private data
  const relevantOrgs = (channel.orgs || []).filter((o) => !!orgNames.find((n) => n === o.name));
  if (relevantOrgs.length < orgNames.length) {
    throw new Error(`Cannot find all orgs for names ${orgNames}`);
  }

  const policy = `OR(${relevantOrgs.map((o) => `'${o.mspName}.member'`).join(",")})`;
  const peerCounts = relevantOrgs.map((o) => (o.anchorPeers || []).length);
  const maxPeerCount = peerCounts.reduce((a, b) => a + b, 0);
  const requiredPeerCount = peerCounts.reduce((a, b) => Math.min(a, b), maxPeerCount) || 1;

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
  network: NetworkSettings,
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
