import * as config from "../config";

// eslint-disable-next-line @typescript-eslint/no-var-requires
const getBuildInfo = (): Record<string, unknown> => require("/fablo/version.json").buildInfo;

const basicInfo = (): Record<string, unknown> => {
  return {
    version: config.fabloVersion,
    build: getBuildInfo(),
  };
};

const fullInfo = (): Record<string, unknown> => {
  return {
    version: config.fabloVersion,
    build: getBuildInfo(),
    supported: {
      fabloVersions: `${config.supportedVersionPrefix}x`,
      hyperledgerFabricVersions: config.supportedFabricVersions,
    },
  };
};

export { getBuildInfo, basicInfo, fullInfo };
