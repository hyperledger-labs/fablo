import * as fs from "fs";
import * as path from "path";
import * as config from "../config";

// version.json is written to the package root by the Docker build; an npm install has none
const versionJsonPath = path.join(__dirname, "../../version.json");

const getBuildInfo = (): unknown =>
  fs.existsSync(versionJsonPath) ? JSON.parse(fs.readFileSync(versionJsonPath, "utf-8")).buildInfo : "";

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
    },
  };
};

export { getBuildInfo, basicInfo, fullInfo };
