import * as config from "../config";

const getBuildInfo = (): Record<string, unknown> => require("/fabrica/version.json");

const basicInfo = (): Record<string, unknown> => {
  return {
    version: config.fabricaVersion,
    build: getBuildInfo(),
  };
};

const fullInfo = (): Record<string, unknown> => {
  return {
    version: config.fabricaVersion,
    build: getBuildInfo(),
    supported: {
      fabricaVersions: `${config.supportedVersionPrefix}x`,
      hyperledgerFabricVersions: config.supportedFabricVersions,
    },
  };
};

export { getBuildInfo, basicInfo, fullInfo };
