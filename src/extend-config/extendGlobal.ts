// Used https://github.com/hyperledger/fabric/blob/v1.4.8/sampleconfig/configtx.yaml for values
import { Capabilities, FabricVersions, Global } from "../types/FabloConfigExtended";
import { version } from "../repositoryUtils";
import { GlobalJson } from "../types/FabloConfigJson";
import defaults from "./defaults";

const getNetworkCapabilities = (fabricVersion: string): Capabilities => {
  if (version(fabricVersion).isGreaterOrEqual("2.0.0"))
    return { channel: "V2_0", orderer: "V2_0", application: "V2_0", isV2: true };

  if (version(fabricVersion).isGreaterOrEqual("1.4.3"))
    return { channel: "V1_4_3", orderer: "V1_4_2", application: "V1_4_2", isV2: false };

  if (version(fabricVersion).isGreaterOrEqual("1.4.2"))
    return { channel: "V1_4_2", orderer: "V1_4_2", application: "V1_4_2", isV2: false };

  return { channel: "V1_3", orderer: "V1_1", application: "V1_3", isV2: false };
};

const getVersions = (fabricVersion: string): FabricVersions => {
  const fabricJavaenvExceptions: Record<string, string> = {
    "1.4.5": "1.4.4",
    "1.4.9": "1.4.8",
    "1.4.10": "1.4.8",
    "1.4.11": "1.4.8",
    "1.4.12": "1.4.8",
    "2.2.2": "2.2.1",
    "2.2.3": "2.2.1",
    "2.3.1": "2.3.0",
    "2.3.2": "2.3.0",
  };

  return {
    fabricVersion,
    fabricCaVersion: version(fabricVersion).isGreaterOrEqual("1.4.10") ? "1.5.0" : fabricVersion,
    fabricCcenvVersion: fabricVersion,
    fabricBaseosVersion: version(fabricVersion).isGreaterOrEqual("2.0") ? fabricVersion : "0.4.9",
    fabricJavaenvVersion: fabricJavaenvExceptions[fabricVersion] ?? fabricVersion,
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
  const monitoring = {
    loglevel: globalJson?.monitoring?.loglevel || defaults.global.monitoring.loglevel,
  };
  const explorer = !globalJson?.tools?.explorer ? {} : { explorer: { address: "explorer.example.com", port: 7010 } };

  return {
    ...globalJson,
    ...getVersions(globalJson.fabricVersion),
    paths: getPathsFromEnv(),
    monitoring,
    capabilities: getNetworkCapabilities(globalJson.fabricVersion),
    tools: { ...explorer },
  };
};

export { getNetworkCapabilities };
export default extendGlobal;
