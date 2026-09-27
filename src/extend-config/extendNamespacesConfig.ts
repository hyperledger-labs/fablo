import { NamespaceJson } from "../types/FabloConfigJson";
import { NamespaceConfig, OrgConfig } from "../types/FabloConfigExtended";
import defaults from "./defaults";

const resolvePolicy = (namespaceJsonFormat: NamespaceJson,  channelOrgs: OrgConfig[]): string => {
  const { name, orgs: namespaceOrgNames, policy } = namespaceJsonFormat;

  if (namespaceOrgNames && policy!== undefined) {
    throw new Error(
      `Namespace '${name}' defines both 'orgs' and 'policy'. Use 'orgs' for the standard case, ` +
        `or 'policy' as an advanced override, not both.`,
    );
  }

  if (policy !== undefined) {
    return policy;
  }

  if (namespaceOrgNames) {
    if (namespaceOrgNames.length === 0) {
      throw new Error(`Namespace '${name}' has an empty 'orgs' list. Declare at least one org, or omit 'orgs'.`);
    }

    const knownOrgNames = channelOrgs.map((o) => o.name);
    const unknownOrgNames = namespaceOrgNames.filter((n) => !knownOrgNames.includes(n));
    if (unknownOrgNames.length > 0) {
      throw new Error(`Namespace '${name}' references unknown org(s): ${unknownOrgNames.join(", ")}.`);
    }

    const selectedOrgs = channelOrgs.filter((o) => namespaceOrgNames.includes(o.name));
    return defaults.namespace.policy(selectedOrgs);
  }


  return defaults.namespace.policy(channelOrgs);
};

const extendNamespaceConfig = (namespaceJsonFormat: NamespaceJson,  channelOrgs: OrgConfig[]): NamespaceConfig => ({
  name: namespaceJsonFormat.name,
  policy: resolvePolicy(namespaceJsonFormat,channelOrgs),
});

const VALID_NAMESPACE_ID = /^[a-z0-9_]+$/;
const MAX_NAMESPACE_ID_LENGTH = 60;

export const checkUniqueNamespaceNames = (namespacesJsonFormat: NamespaceJson[]): void => {
  const namespaceNames = new Set<string>();

  namespacesJsonFormat.forEach((namespace) => {
    if (!VALID_NAMESPACE_ID.test(namespace.name) || namespace.name.length > MAX_NAMESPACE_ID_LENGTH) {
      throw new Error(
        `Namespace '${namespace.name}' is not a valid Fabric-X namespace ID - only lowercase letters, ` +
        `digits, and underscores are allowed (no hyphens), max 60 characters.`,
      );
    }

    if (namespaceNames.has(namespace.name)) {
      throw new Error(`Duplicate namespace '${namespace.name}' found. Namespace names must be unique.`);
    }
    namespaceNames.add(namespace.name);
  });
};

const extendNamespacesConfig = (namespacesJsonFormat: NamespaceJson[], channelOrgs: OrgConfig[]): NamespaceConfig[] => {
  checkUniqueNamespaceNames(namespacesJsonFormat);
  return namespacesJsonFormat.map((ns) => extendNamespaceConfig(ns, channelOrgs));
};

export default extendNamespacesConfig;