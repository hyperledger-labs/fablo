// Used https://github.com/hyperledger/fabric/blob/v1.4.8/sampleconfig/configtx.yaml for values
import { Capabilities, FabricImages, FabricVersions, Global } from "../types/FabloConfigExtended";
import { version } from "../repositoryUtils";
import { FabricImagesJson, GlobalJson } from "../types/FabloConfigJson";
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

  const is_or_above3_0_0 = (v: string) => (v.startsWith("3.") ? "3.0.0" : v);

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

const getImages = (fabricVersion: string, fabricImages?: FabricImagesJson): FabricImages => {
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
    peerImage: toImage(baseImages.peerImage, "${FABRIC_VERSION}"),
    ordererImage: toImage(baseImages.ordererImage, "${FABRIC_VERSION}"),
    caImage: toImage(baseImages.caImage, "${FABRIC_CA_VERSION}"),
    toolsImage: toImage(baseImages.toolsImage, "${FABRIC_TOOLS_VERSION}"),
    ccenvImage: toImage(baseImages.ccenvImage, "${FABRIC_CCENV_VERSION}"),
    baseosImage: toImage(baseImages.baseosImage, "${FABRIC_BASEOS_VERSION}"),
    javaenvImage: toImage(baseImages.javaenvImage, "${FABRIC_JAVAENV_VERSION}"),
    nodeenvImage: toImage(baseImages.nodeenvImage, "${FABRIC_NODEENV_VERSION}"),
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
  const { fabricImages, ...globalJsonRest } = globalJson;
  const images = getImages(globalJson.fabricVersion, fabricImages);
  const engine = globalJson.engine ?? "docker";

  const monitoring = {
    loglevel: globalJson?.monitoring?.loglevel || defaults.global.monitoring.loglevel,
  };

  const explorer = !globalJson?.tools?.explorer
    ? {}
    : {
        explorer: { address: "explorer.example.com", port: 7010 },
      };

  return {
    ...globalJsonRest,
    ...getVersions(globalJson.fabricVersion),
    ...images,
    engine,
    paths: getPathsFromEnv(),
    monitoring,
    capabilities: getNetworkCapabilities(globalJson.fabricVersion),
    tools: { ...explorer },
  };
};

export { getNetworkCapabilities };
export default extendGlobal;
