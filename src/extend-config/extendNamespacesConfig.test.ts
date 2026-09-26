import extendNamespacesConfig from  "./extendNamespacesConfig";
import { OrgConfig } from "../types/FabloConfigExtended";

const org = (name: string, mspName: string): OrgConfig =>
({
  name,
  mspName,
} as OrgConfig);

describe("extendNamespacesConfig", () => {
  it("should derive AND(...) from 'orgs', in channel-org order", () => {
    const namespaces = extendNamespacesConfig(
      [{ name: "mynamespace", orgs: ["Org1", "Org2"] }],
      [org("Org1", "Org1MSP"), org("Org2", "Org2MSP")],
    );

    expect(namespaces).toEqual([{ name: "mynamespace", policy: "AND('Org1MSP.member','Org2MSP.member')" }]);
  });

  it("should keep an explicit policy override as-is", () => {
    const namespaces = extendNamespacesConfig(
      [{ name: "mynamespace", policy: "OutOf(1, 'Org1MSP.member')" }],
      [org("Org1", "Org1MSP")],
    );

    expect(namespaces).toEqual([{ name: "mynamespace", policy: "OutOf(1, 'Org1MSP.member')" }]);
  });

  it("should default to an AND of every channel org when neither 'orgs' nor 'policy' is given", () => {
    const namespaces = extendNamespacesConfig(
      [{ name: "mynamespace" }],
      [org("Org1", "Org1MSP"), org("Org2", "Org2MSP")],
    );

    expect(namespaces).toEqual([{ name: "mynamespace", policy: "AND('Org1MSP.member','Org2MSP.member')" }]);
  });

  it("should extend multiple namespaces independently", () => {
    const namespaces = extendNamespacesConfig(
      [{ name: "ns1" }, { name: "ns2", policy: "OutOf(1, 'Org1MSP.member')" }],
      [org("Org1", "Org1MSP")],
    );

    expect(namespaces).toEqual([
      { name: "ns1", policy: "AND('Org1MSP.member')" },
      { name: "ns2", policy: "OutOf(1, 'Org1MSP.member')" },
    ]);
  });

  it("should throw on duplicate namespace names", () => {
    expect(() =>
      extendNamespacesConfig([{ name: "mynamespace" }, { name: "mynamespace" }], [org("Org1", "Org1MSP")]),
    ).toThrow("Duplicate namespace 'mynamespace' found. Namespace names must be unique.");
  });

  it("should throw when both 'orgs' and 'policy' are given", () => {
    expect(() =>
      extendNamespacesConfig(
        [{ name: "mynamespace", orgs: ["Org1"], policy: "AND('Org1MSP.member')" }],
        [org("Org1", "Org1MSP")],
      ),
    ).toThrow("Namespace 'mynamespace' defines both 'orgs' and 'policy'");
  });
  
  it("should throw when 'orgs' is given alongside an explicitly empty-string policy", () => {
    expect(() =>
      extendNamespacesConfig([{ name: "mynamespace", orgs: ["Org1"], policy: "" }], [org("Org1", "Org1MSP")]),
    ).toThrow("Namespace 'mynamespace' defines both 'orgs' and 'policy'");
  });
 
  it("should throw when 'orgs' is an empty list", () => {
    expect(() => extendNamespacesConfig([{ name: "mynamespace", orgs: [] }], [org("Org1", "Org1MSP")])).toThrow(
      "Namespace 'mynamespace' has an empty 'orgs' list",
    );
  });

  it("should throw when 'orgs' references an org that isn't a member of the channel", () => {
    expect(() => extendNamespacesConfig([{ name: "mynamespace", orgs: ["Org2"] }], [org("Org1", "Org1MSP")])).toThrow(
      "Namespace 'mynamespace' references unknown org(s): Org2.",
    );
  });

  it("should throw when the namespace name contains a hyphen (invalid fxconfig namespace ID)", () => {

    expect(() => extendNamespacesConfig([{ name: "audit-ns" }], [org("Org1", "Org1MSP")])).toThrow(
      "Namespace 'audit-ns' is not a valid Fabric-X namespace ID",
    );
  });

  it("should throw when the namespace name exceeds 60 characters", () => {
    const longName = "a".repeat(61);
    expect(() => extendNamespacesConfig([{ name: longName }], [org("Org1", "Org1MSP")])).toThrow(
      `Namespace '${longName}' is not a valid Fabric-X namespace ID`,
    );
  });
});