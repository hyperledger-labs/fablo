import * as ejs from "ejs";
import * as fs from "fs";
import * as path from "path";
import { execSync } from "child_process";
import { shellQuote } from "../utils/shellQuote";

describe("fabric-x base-functions.sh namespaceInit", () => {
  const templatePath = path.join(__dirname, "templates/fabric-x/scripts/base-functions.sh");
  const template = fs.readFileSync(templatePath, "utf-8");

  const namespaces = [
    { name: "mynamespace", policy: "AND('Org1MSP.member')" },
    { name: "audit-ns", policy: "OutOf(1, 'Org1MSP.member')" },
  ];

  const rendered = ejs.render(template, { namespaces, shellQuote });


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
    expect(stdout).toContain("CALLED name=audit-ns policy=OutOf(1, 'Org1MSP.member')");
  });

  it("creates only the targeted namespace when a name is given", () => {
    const { stdout, status } = runNamespaceInit("audit-ns");

    expect(status).toBe(0);
    expect(stdout).not.toContain("name=mynamespace");
    expect(stdout).toContain("CALLED name=audit-ns policy=OutOf(1, 'Org1MSP.member')");
  });

  it("fails with a non-zero exit code for an unknown namespace name", () => {
    const { stdout, status } = runNamespaceInit("does-not-exist");

    expect(status).not.toBe(0);
    expect(stdout).not.toContain("CALLED");
  });
});