import { NamespaceJson } from "../types/FabloConfigJson";
import { NamespaceConfig, OrgConfig } from "../types/FabloConfigExtended";
import defaults from "./defaults";

const resolvePolicy = (namespaceJsonFormat: NamespaceJson, orgsTransformed: OrgConfig[]): string => {
  const { name, orgs: namespaceOrgNames, policy } = namespaceJsonFormat;

  if (namespaceOrgNames && policy) {
    throw new Error(
      `Namespace '${name}' defines both 'orgs' and 'policy'. Use 'orgs' for the standard case, ` +
        `or 'policy' as an advanced override, not both.`,
    );
  }

  if (policy) {
    return policy;
  }

  if (namespaceOrgNames) {
    const knownOrgNames = orgsTransformed.map((o) => o.name);
    const unknownOrgNames = namespaceOrgNames.filter((n) => !knownOrgNames.includes(n));
    if (unknownOrgNames.length > 0) {
      throw new Error(`Namespace '${name}' references unknown org(s): ${unknownOrgNames.join(", ")}.`);
    }

    const selectedOrgs = orgsTransformed.filter((o) => namespaceOrgNames.includes(o.name));
    return defaults.namespace.policy(selectedOrgs);
  }

  return defaults.namespace.policy(orgsTransformed);
};

const extendNamespaceConfig = (namespaceJsonFormat: NamespaceJson, orgsTransformed: OrgConfig[]): NamespaceConfig => ({
  name: namespaceJsonFormat.name,
  policy: resolvePolicy(namespaceJsonFormat, orgsTransformed),
});

export const checkUniqueNamespaceNames = (namespacesJsonFormat: NamespaceJson[]): void => {
  const namespaceNames = new Set<string>();

  namespacesJsonFormat.forEach((namespace) => {
    if (namespaceNames.has(namespace.name)) {
      throw new Error(`Duplicate namespace '${namespace.name}' found. Namespace names must be unique.`);
    }
    namespaceNames.add(namespace.name);
  });
};

const extendNamespacesConfig = (namespacesJsonFormat: NamespaceJson[], orgsTransformed: OrgConfig[]): NamespaceConfig[] => {
  checkUniqueNamespaceNames(namespacesJsonFormat);
  return namespacesJsonFormat.map((ns) => extendNamespaceConfig(ns, orgsTransformed));
};

export default extendNamespacesConfig;