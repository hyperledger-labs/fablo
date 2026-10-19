import * as ejs from "ejs";
import * as fs from "fs";
import * as path from "path";
import { execSync } from "child_process";
import { shellQuote } from "../utils/shellQuote";
import { getFabricXTemplateModel } from "./fabricXDockerWriter";
import { FabloConfigExtended } from "../types/FabloConfigExtended";

describe("fabric-x base-functions.sh namespaceInit", () => {
  const templatePath = path.join(__dirname, "templates/fabric-x/scripts/base-functions.sh");
  const template = fs.readFileSync(templatePath, "utf-8");

  const namespaces = [
    { name: "mynamespace", policy: "AND('Org1MSP.member')" },
    { name: "audit_ns", policy: "OutOf(1, 'Org1MSP.member')" },
  ];

  const rendered = ejs.render(template, {
    namespaces,
    fabricX: {
      channelName: "mychannel",
      channelProfileName: "SampleFabricXChannel",
      applicationOrgs: [
        {
          name: "Org1",
          domain: "org1.example.com",
          mspName: "Org1MSP",
          slug: "org1",
          sidecarPort: 4001,
          queryServicePort: 8001,
        },
      ],
      defaultPolicy: "AND('Org1MSP.member')",
    },
    shellQuote,
  });

  const scriptWithStub = `${rendered}\nnamespaceCreate() { echo "CALLED name=$1 policy=$2"; }\n`;

  const runNamespaceInit = (target: string): { stdout: string; status: number } => {
    const script = `set -eu\n${scriptWithStub}\nnamespaceInit ${target ? `"${target}"` : '""'}`;
    try {
      const stdout = execSync(script, { shell: "/bin/bash", encoding: "utf-8" });
      return { stdout, status: 0 };
    } catch (e) {
      const err = e as { stdout?: string; status?: number };
      return { stdout: err.stdout ?? "", status: err.status ?? 1 };
    }
  };

  it("creates every configured namespace when called with no target", () => {
    const { stdout, status } = runNamespaceInit("");

    expect(status).toBe(0);
    expect(stdout).toContain("CALLED name=mynamespace policy=AND('Org1MSP.member')");
    expect(stdout).toContain("CALLED name=audit_ns policy=OutOf(1, 'Org1MSP.member')");
  });

  it("creates only the targeted namespace when a name is given", () => {
    const { stdout, status } = runNamespaceInit("audit_ns");

    expect(status).toBe(0);
    expect(stdout).not.toContain("name=mynamespace");
    expect(stdout).toContain("CALLED name=audit_ns policy=OutOf(1, 'Org1MSP.member')");
  });

  it("fails with a non-zero exit code for an unknown namespace name", () => {
    const { stdout, status } = runNamespaceInit("does-not-exist");

    expect(status).not.toBe(0);
    expect(stdout).not.toContain("CALLED");
  });
});

describe("getFabricXTemplateModel", () => {
  it("resolves multi-org topology with port offsets and combined policy", () => {
    const configExtended = {
      orgs: [
        { name: "Org1", domain: "org1.com", mspName: "Org1MSP" },
        { name: "Org2", domain: "org2.com", mspName: "Org2MSP" },
      ],
      channels: [
        {
          name: "my-channel",
          profileName: "MyChannel",
          orgs: [
            { name: "Org1", domain: "org1.com", mspName: "Org1MSP" },
            { name: "Org2", domain: "org2.com", mspName: "Org2MSP" },
          ],
        },
      ],
    };

    const model = getFabricXTemplateModel(configExtended as unknown as FabloConfigExtended);

    expect(model.channelName).toBe("my-channel");
    expect(model.channelProfileName).toBe("MyChannel");
    expect(model.applicationOrgs[0].name).toBe("Org1");
    expect(model.applicationOrgs).toHaveLength(2);
    expect(model.applicationOrgs[0].slug).toBe("org1");
    expect(model.applicationOrgs[0].sidecarPort).toBe(4001);
    expect(model.applicationOrgs[0].queryServicePort).toBe(8001);
    expect(model.applicationOrgs[1].slug).toBe("org2");
    expect(model.applicationOrgs[1].sidecarPort).toBe(4002);
    expect(model.applicationOrgs[1].queryServicePort).toBe(8002);
    expect(model.defaultPolicy).toBe("AND('Org1MSP.member','Org2MSP.member')");
  });

  it("throws when channel is missing or channel has no organizations", () => {
    expect(() => getFabricXTemplateModel({ channels: [] } as unknown as FabloConfigExtended)).toThrow(
      "Fabric-X generation requires exactly one channel.",
    );

    expect(() =>
      getFabricXTemplateModel({
        channels: [{ name: "my-channel", profileName: "MyChannel", orgs: [] }],
      } as unknown as FabloConfigExtended),
    ).toThrow("Fabric-X generator requires at least one channel with an organization.");
  });
});
