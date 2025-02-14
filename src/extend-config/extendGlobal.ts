// Used https://github.com/hyperledger/fabric/blob/v1.4.8/sampleconfig/configtx.yaml for values
import { Capabilities, FabricVersions, Global } from "../types/FabloConfigExtended";
import { version } from "../repositoryUtils";
import { GlobalJson } from "../types/FabloConfigJson";
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

  const beta3_0_0 = (v: string) => (v.startsWith("3.0.") ? "3.0.0-beta" : v);

  return {
    fabricVersion,
    fabricToolsVersion: beta3_0_0(fabricVersion),
    fabricCaVersion: version(fabricVersion).isGreaterOrEqual("1.4.10") ? "1.5.5" : fabricVersion,
    fabricCcenvVersion: fabricVersion,
    fabricBaseosVersion: version(fabricVersion).isGreaterOrEqual("2.0") ? fabricVersion : "0.4.9",
    fabricJavaenvVersion: below3_0_0(majorMinor),
    fabricNodeenvVersion: fabricNodeenvExceptions[fabricVersion] ?? below3_0_0(majorMinor),
    fabricRecommendedNodeVersion: version(fabricVersion).isGreaterOrEqual("2.4") ? "16" : "12",
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
    engine,
    ...globalJson,
    ...getVersions(globalJson.fabricVersion),
    paths: getPathsFromEnv(),
    serviceDiscoveryOn: !globalJson.peerDevMode,
    monitoring,
    capabilities: getNetworkCapabilities(globalJson.fabricVersion),
    tools: { ...explorer },
  };
};

export { getNetworkCapabilities };
export default extendGlobal;
