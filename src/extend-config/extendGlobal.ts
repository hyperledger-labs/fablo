// Used https://github.com/hyperledger/fabric/blob/v1.4.8/sampleconfig/configtx.yaml for values
import { Capabilities, FabricImages, FabricVersions, Global, FabricXExtended, FabricXServiceComponent, FabricXCommitterComponent } from "../types/FabloConfigExtended";
import { version } from "../repositoryUtils";
import { FabricImagesJson, GlobalJson, FabricXConfigJson } from "../types/FabloConfigJson";
import defaults from "./defaults";

const getNetworkCapabilities = (fabricVersion: string): Capabilities => {
  if (version(fabricVersion).isGreaterOrEqual("2.5.0") && !version(fabricVersion).isGreaterOrEqual("3.0.0"))
    return { channel: "V2_0", orderer: "V2_0", application: "V2_5", isV2: true, isV3: false };

  if (version(fabricVersion).isGreaterOrEqual("3.0.0"))
    return { channel: "V3_0", orderer: "V2_0", application: "V2_5", isV2: false, isV3: true };

  return { channel: "V2_0", orderer: "V2_0", application: "V2_0", isV2: true, isV3: false };
};

const getVersions = (fabricVersion: string): FabricVersions => {
  const majorMinor = version(fabricVersion).takeMajorMinor();

  const fabricNodeenvExceptions: Record<string, string> = {
    "2.4": "2.4.2",
    "2.4.1": "2.4.2",
  };

  const below3_0_0 = (v: string) => (v.startsWith("3.") ? "2.5" : v);

  const is_or_above3_0_0 = (v: string) => (v.startsWith("3.") ? "3.1.3" : v);

  return {
    fabricVersion,
    fabricToolsVersion: is_or_above3_0_0(fabricVersion),
    fabricCaVersion: version(fabricVersion).isGreaterOrEqual("1.4.10") ? "1.5.16" : fabricVersion,
    fabricCcenvVersion: fabricVersion,
    fabricBaseosVersion: version(fabricVersion).isGreaterOrEqual("2.0") ? fabricVersion : "0.4.9",
    fabricJavaenvVersion: below3_0_0(majorMinor),
    fabricNodeenvVersion: fabricNodeenvExceptions[fabricVersion] ?? below3_0_0(majorMinor),
    fabricRecommendedNodeVersion: version(fabricVersion).isGreaterOrEqual("2.4") ? "16" : "12",
  };
};

const hasTagOrDigest = (image: string): boolean => {
  if (image.includes("@")) return true;
  const lastSlash = image.lastIndexOf("/");
  const lastColon = image.lastIndexOf(":");
  return lastColon > lastSlash;
};

const toImage = (image: string, defaultTag: string): string =>
  hasTagOrDigest(image) ? image : `${image}:${defaultTag}`;

const getImages = (fabricVersion: string, versions: FabricVersions, fabricImages?: FabricImagesJson): FabricImages => {
  const defaultToolsImage = version(fabricVersion).isGreaterOrEqual("3.0.0")
    ? "ghcr.io/fablo-io/fabric-tools"
    : "hyperledger/fabric-tools";

  const baseImages = {
    peerImage: fabricImages?.peer ?? "hyperledger/fabric-peer",
    ordererImage: fabricImages?.orderer ?? "hyperledger/fabric-orderer",
    caImage: fabricImages?.ca ?? "hyperledger/fabric-ca",
    toolsImage: fabricImages?.tools ?? defaultToolsImage,
    ccenvImage: fabricImages?.ccenv ?? "hyperledger/fabric-ccenv",
    baseosImage: fabricImages?.baseos ?? "hyperledger/fabric-baseos",
    javaenvImage: fabricImages?.javaenv ?? "hyperledger/fabric-javaenv",
    nodeenvImage: fabricImages?.nodeenv ?? "hyperledger/fabric-nodeenv",
  };

  return {
    peerImage: toImage(baseImages.peerImage, versions.fabricVersion),
    ordererImage: toImage(baseImages.ordererImage, versions.fabricVersion),
    caImage: toImage(baseImages.caImage, versions.fabricCaVersion),
    toolsImage: toImage(baseImages.toolsImage, versions.fabricToolsVersion),
    ccenvImage: toImage(baseImages.ccenvImage, versions.fabricCcenvVersion),
    baseosImage: toImage(baseImages.baseosImage, versions.fabricBaseosVersion),
    javaenvImage: toImage(baseImages.javaenvImage, versions.fabricJavaenvVersion),
    nodeenvImage: toImage(baseImages.nodeenvImage, versions.fabricNodeenvVersion),
  };
};

const getEnvVarOrThrow = (name: string): string => {
  const value = process.env[name];
  if (!value || !value.length) throw new Error(`Missing environment variable ${name}`);
  return value;
};

const getPathsFromEnv = () => ({
  fabloConfig: getEnvVarOrThrow("FABLO_CONFIG"),
  chaincodesBaseDir: getEnvVarOrThrow("CHAINCODES_BASE_DIR"),
});

const extendGlobal = (globalJson: GlobalJson): Global => {
  const { fabricImages, fabricX: fabricXJson, ...globalJsonRest } = globalJson;
  const versions = getVersions(globalJson.fabricVersion);
  const images = getImages(globalJson.fabricVersion, versions, fabricImages);
  const engine = globalJson.engine ?? "docker";

  const monitoring = {
    loglevel: globalJson?.monitoring?.loglevel || defaults.global.monitoring.loglevel,
  };

  const explorer = !globalJson?.tools?.explorer
    ? {}
    : {
      explorer: { address: "explorer.example.com", port: 7010 },
    };

  const paths = process.env.FABLO_CONFIG ? getPathsFromEnv() : {
    fabloConfig: "fablo-config.json",
    chaincodesBaseDir: ".",
  };

  return {
    ...globalJsonRest,
    ...versions,
    ...images,
    engine,
    paths,
    monitoring,
    capabilities: getNetworkCapabilities(globalJson.fabricVersion),
    tools: { ...explorer },
    ...(fabricXJson ? { fabricX: extendFabricX(fabricXJson) } : {}),
  };
};

// =============================================
// Fabric-X Extension Logic
// =============================================

const makeComponent = (name: string, basePort: number, index: number): FabricXServiceComponent => ({
  name: `${name}${index}`,
  address: `${name}${index}.fabricx.example.com`,
  port: basePort + index,
  containerName: `${name}${index}.fabricx.example.com`,
});

const extendFabricX = (fabricXJson: FabricXConfigJson): FabricXExtended => {
  const { orderer, committer, version } = fabricXJson;

  // Generate orderer components with sequential ports
  const routers: FabricXServiceComponent[] = [];
  for (let i = 0; i < orderer.routerInstances; i++) {
    routers.push(makeComponent("router", 10000, i));
  }

  const batchers: FabricXServiceComponent[] = [];
  let batcherIdx = 0;
  for (let shard = 0; shard < orderer.batcherShards; shard++) {
    for (let b = 0; b < orderer.batchersPerShard; b++) {
      batchers.push(makeComponent("batcher", 10100, batcherIdx));
      batcherIdx++;
    }
  }

  const consenters: FabricXServiceComponent[] = [];
  for (let i = 0; i < orderer.consenterInstances; i++) {
    consenters.push(makeComponent("consenter", 10200, i));
  }

  const assemblers: FabricXServiceComponent[] = [];
  for (let i = 0; i < orderer.assemblerInstances; i++) {
    assemblers.push(makeComponent("assembler", 10300, i));
  }

  // Generate committer stacks — each committer has 5 sub-services
  const committers: FabricXCommitterComponent[] = [];
  for (let i = 0; i < committer.instances; i++) {
    const basePort = 10400 + i * 10;
    committers.push({
      name: `committer${i}`,
      orgName: "Org1",
      orgDomain: "org1.example.com",
      sidecar: makeComponent(`committer${i}-sidecar`, basePort, 0),
      coordinator: makeComponent(`committer${i}-coordinator`, basePort + 1, 0),
      validatorCommitter: makeComponent(`committer${i}-vc`, basePort + 2, 0),
      verificationService: makeComponent(`committer${i}-verification`, basePort + 3, 0),
      queryService: makeComponent(`committer${i}-query`, basePort + 4, 0),
    });
  }

  return {
    version,
    routers,
    batchers,
    consenters,
    assemblers,
    committers,
  };
};

export { getNetworkCapabilities };
export default extendGlobal;
