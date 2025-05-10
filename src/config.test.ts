import { fabloVersion, getVersionFromSchemaUrl, isFabloVersionSupported, supportedVersionPrefix, versionsSupportingRaft } from "./config";

it("should get version from schema URL", () => {
  const url = "https://github.com/hyperledger-labs/fablo/releases/download/0.0.1/schema.json";
  const version = getVersionFromSchemaUrl(url);
  expect(version).toEqual("0.0.1");
});

it("should get current version in case of missing schema URL", () => {
  const version = getVersionFromSchemaUrl(undefined);
  expect(version).toEqual(fabloVersion);
});

it("should check if version is supported", () => {
  const currentMajorMinor = supportedVersionPrefix.slice(0, -1);
  expect(isFabloVersionSupported(`${currentMajorMinor}.0`)).toBeTruthy();
  expect(isFabloVersionSupported(`${currentMajorMinor}.999`)).toBeTruthy();
  expect(isFabloVersionSupported("0.0.1")).toBeFalsy();
});

it("should check versions supporting raft", () => {
  expect(versionsSupportingRaft("1.4.3")).toBeTruthy();
  expect(versionsSupportingRaft("1.4.4")).toBeTruthy();
  expect(versionsSupportingRaft("2.0.0")).toBeTruthy();
  expect(versionsSupportingRaft("1.4.2")).toBeFalsy();
  expect(versionsSupportingRaft("1.3.0")).toBeFalsy();
});
