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
  const requiredPeerCount = anchorPeerCountsInChannel.reduce((a, b) => Math.min(a, b), maxPeerCount);

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

const checkUniqueChaincodeNames = (chaincodes: ChaincodeJson[]): void => {
  const chaincodeKeys = new Set<string>();

  chaincodes.forEach((chaincode) => {
    const chaincodeKey = `${chaincode.channel}.${chaincode.name}`;
    if (chaincodeKeys.has(chaincodeKey)) {
      const msg = `Duplicate chaincode '${chaincode.name}' found in channel '${chaincode.channel}'. Chaincode names must be unique within a channel.`;
      throw new Error(msg);
    }
    chaincodeKeys.add(chaincodeKey);
  });
};

const extendChaincodesConfig = (
  chaincodes: ChaincodeJson[],
  transformedChannels: ChannelConfig[],
  network: Global,
): ChaincodeConfig[] => {
  checkUniqueChaincodeNames(chaincodes);
  return chaincodes.map((chaincode, index) => {
    const channel = transformedChannels.find((c) => c.name === chaincode.channel);
    if (!channel) throw new Error(`No matching channel with name '${chaincode.channel}'`);

    const initParams: { initRequired: boolean } | { init: string } = network.capabilities.isV2
      ? { initRequired: chaincode.initRequired || defaults.chaincode.initRequired }
      : { init: chaincode.init || defaults.chaincode.init };

    const ccaasParams =
      chaincode.lang === "ccaas"
        ? { chaincodeMountPath: chaincode.chaincodeMountPath, chaincodeStartCommand: chaincode.chaincodeStartCommand }
        : {};

    const endorsement = chaincode.endorsement ?? defaults.chaincode.endorsement(channel.orgs, network.capabilities);

    const privateData = (chaincode.privateData ?? []).map((d) =>
      createPrivateCollectionConfig(network.fabricVersion, channel, d.name, d.orgNames),
    );

    const privateDataConfigFile =
      privateData.length > 0 ? `collections/${chaincode.channel}-${chaincode.name}.json` : undefined;

    const peerChaincodeInstances = !chaincode.image
      ? []
      : channel.orgs.flatMap((org) =>
          org.peers.map((peer) => {
            const versionSuffix = `${chaincode.version}`.replace(/[^a-zA-Z0-9_.-]/g, "_");
            const containerName = `ccaas_${peer.address.replace(/[^a-zA-Z0-9_.-]/g, "_")}_${channel.name}_${
              chaincode.name
            }_${versionSuffix}`.toLowerCase();
            return {
              containerName,
              peerAddress: peer.address,
              port: 10000 * (index + 1) + peer.port,
              orgDomain: org.domain,
            };
          }),
        );

    if (chaincode.lang === "ccaas") {
      if (!chaincode.image) {
        throw new Error(`Chaincode '${chaincode.name}' of type 'ccaas' must specify an image field`);
      }
    }

    if (chaincode.lang !== "ccaas") {
      if (!chaincode.directory) {
        throw new Error(`Chaincode '${chaincode.name}' of type '${chaincode.lang}' must specify a directory field`);
      }
      if (chaincode.chaincodeMountPath) {
        throw new Error(`chaincodeMountPath is not supported for chaincode type '${chaincode.lang}'`);
      }
      if (chaincode.chaincodeStartCommand) {
        throw new Error(`chaincodeStartCommand is not supported for chaincode type '${chaincode.lang}'`);
      }
    }

    // Normalize directory to support leading './'
    const normalizedDirectory = chaincode.directory?.replace(/^\.\//, "");

    return {
      directory: normalizedDirectory,
      name: chaincode.name,
      version: chaincode.version,
      lang: chaincode.lang,
      channel,
      image: chaincode.image,
      ...initParams,
      ...ccaasParams,
      endorsement,
      instantiatingOrg: channel.instantiatingOrg,
      privateDataConfigFile,
      peerChaincodeInstances,
      privateData,
    };
  });
};

export { checkUniqueChaincodeNames };

export default extendChaincodesConfig;
