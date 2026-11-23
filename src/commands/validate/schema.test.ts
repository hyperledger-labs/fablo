import * as fs from "fs";
import * as path from "path";
import { Validator } from "jsonschema";
import * as config from "../../config";

const readJson = (relativePath: string) =>
  JSON.parse(fs.readFileSync(path.join(__dirname, "../../..", relativePath), "utf-8"));

const errorsOf = (json: unknown): string[] =>
  new Validator().validate(json, config.schema).errors.map((error) => `${error.property} ${error.message}`);

describe("schema rules per provider", () => {
  const classicConfig = () => readJson("docs/sample.json");
  const fabricXConfig = () => readJson("samples/fablo-config-fabric-x-2orgs.json");

  it("should accept the sample configs", () => {
    expect(errorsOf(classicConfig())).toEqual([]);
    expect(errorsOf(fabricXConfig())).toEqual([]);
  });

  it("should accept a fabric-x config without the values that have defaults", () => {
    // given
    const json = fabricXConfig();

    // then
    expect(json.global).toEqual({ provider: "fabric-x" });
    expect(json.channels[0].orgs).toBeUndefined();
    expect(json.chaincodes).toBeUndefined();
    expect(errorsOf(json)).toEqual([]);
  });

  it("should still require the existing fields for the fabric provider", () => {
    const withoutChaincodes = classicConfig();
    delete withoutChaincodes.chaincodes;
    const withoutVersion = classicConfig();
    delete withoutVersion.global.fabricVersion;
    const withoutTls = classicConfig();
    delete withoutTls.global.tls;
    const withoutChannelOrgs = classicConfig();
    delete withoutChannelOrgs.channels[0].orgs;
    const withoutChannelPeers = classicConfig();
    delete withoutChannelPeers.channels[0].orgs[0].peers;

    expect(errorsOf(withoutChaincodes)).toEqual(['instance requires property "chaincodes"']);
    expect(errorsOf(withoutVersion)).toEqual(['instance.global requires property "fabricVersion"']);
    expect(errorsOf(withoutTls)).toEqual(['instance.global requires property "tls"']);
    expect(errorsOf(withoutChannelOrgs)).toEqual(['instance.channels[0] requires property "orgs"']);
    expect(errorsOf(withoutChannelPeers)).toEqual(['instance.channels[0].orgs[0] requires property "peers"']);
  });

  it("should require namespaces for the fabric-x provider", () => {
    const json = fabricXConfig();
    delete json.namespaces;

    expect(errorsOf(json)).toEqual(['instance requires property "namespaces"']);
  });

  it("should reject malformed values for the fabric-x provider", () => {
    const nullCa = fabricXConfig();
    nullCa.orgs[0].ca = null;
    const withoutOrgs = fabricXConfig();
    delete withoutOrgs.orgs;
    const stringTls = fabricXConfig();
    stringTls.global.tls = "yes";
    const stringPartyCount = fabricXConfig();
    stringPartyCount.fabricX = { orderer: { partyCount: "4" } };

    expect(errorsOf(nullCa)).toEqual(["instance.orgs[0].ca is not of a type(s) object"]);
    expect(errorsOf(withoutOrgs)).toEqual(['instance requires property "orgs"']);
    expect(errorsOf(stringTls)).toEqual(["instance.global.tls is not of a type(s) boolean"]);
    expect(errorsOf(stringPartyCount)).toEqual(["instance.fabricX.orderer.partyCount is not of a type(s) integer"]);
  });
});
