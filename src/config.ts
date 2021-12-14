// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
import { version as fabloVersion } from "../package.json";
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
import * as schemaJson from "../docs/schema.json";
import { Schema } from "jsonschema";
import { version } from "./repositoryUtils";

const schema: Schema = schemaJson as Schema;

const supportedVersionPrefix = `${fabloVersion.split(".").slice(0, 2).join(".")}.`;

const getVersionFromSchemaUrl = (url?: string): string => {
  const matches = (url || "").match(/\d+\.\d+\.\d+/g);
  return matches?.length ? matches[0] : fabloVersion;
};

const isFabloVersionSupported = (versionName: string): boolean => versionName.startsWith(supportedVersionPrefix);

const supportedFabricVersions = schemaJson.properties.global.properties.fabricVersion.enum as string[];

const versionsSupportingRaft = supportedFabricVersions.filter((v) => version(v).isGreaterOrEqual("1.4.3"));

const splashScreen = (): string =>
  `${
    "Fablo is powered by :\n" +
    " _____        __ _                         ___  ____ _ _ \n" +
    "/  ___|      / _| |                        |  \\/  (_) | |\n" +
    "\\ `--.  ___ | |_| |___      ____ _ _ __ ___| .  . |_| | |\n" +
    " `--. \\/ _ \\|  _| __\\ \\ /\\ / / _` | '__/ _ \\ |\\/| | | | |\n" +
    "/\\__/ / (_) | | | |_ \\ V  V / (_| | | |  __/ |  | | | | |\n" +
    "\\____/ \\___/|_|  \\__| \\_/\\_/ \\__,_|_|  \\___\\_|  |_/_|_|_|\n" +
    "=========================================================== v: "
  }${fabloVersion}`;

export {
  schema,
  splashScreen,
  fabloVersion,
  supportedFabricVersions,
  versionsSupportingRaft,
  getVersionFromSchemaUrl,
  isFabloVersionSupported,
  supportedVersionPrefix,
};
