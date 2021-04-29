// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
import { version as fabricaVersion } from "../package.json";
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
import * as schema from "../docs/schema.json";
import { version } from "./repositoryUtils";

const supportedVersionPrefix = `${fabricaVersion.split(".").slice(0, 2).join(".")}.`;

const getVersionFromSchemaUrl = (url: string): string => {
  const matches = (url || "").match(/\d+\.\d+\.\d+/g);
  return matches?.length ? matches[0] : fabricaVersion;
};

const isFabricaVersionSupported = (versionName: string): boolean => versionName.startsWith(supportedVersionPrefix);

const supportedFabricVersions = schema.properties.networkSettings.properties.fabricVersion.enum;

const versionsSupportingRaft = supportedFabricVersions.filter((v) => version(v).isGreaterOrEqual("1.4.3"));

const splashScreen = (): string =>
  `${
    "Fabrica is powered by :\n" +
    " _____        __ _                         ___  ____ _ _ \n" +
    "/  ___|      / _| |                        |  \\/  (_) | |\n" +
    "\\ `--.  ___ | |_| |___      ____ _ _ __ ___| .  . |_| | |\n" +
    " `--. \\/ _ \\|  _| __\\ \\ /\\ / / _` | '__/ _ \\ |\\/| | | | |\n" +
    "/\\__/ / (_) | | | |_ \\ V  V / (_| | | |  __/ |  | | | | |\n" +
    "\\____/ \\___/|_|  \\__| \\_/\\_/ \\__,_|_|  \\___\\_|  |_/_|_|_|\n" +
    "=========================================================== v: "
  }${fabricaVersion}`;

export {
  splashScreen,
  fabricaVersion,
  supportedFabricVersions,
  versionsSupportingRaft,
  getVersionFromSchemaUrl,
  isFabricaVersionSupported,
  supportedVersionPrefix,
};
