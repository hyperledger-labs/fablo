const root = 'root';
const otherOrgs = 'orgs';

function isOrganizationWithKey(orgKey) {
  return (o) => o.organization.key === orgKey;
}

async function loadConfig(config, orgKey, key) {
  const current = orgKey === root
    ? await config.get(root)
    : ((await config.get(otherOrgs)) || []).find(isOrganizationWithKey(orgKey));
  return (current || {})[key] || {};
}

async function saveConfig(config, orgKey, key, value) {
  if (orgKey === root) {
    const current = await config.get(root);
    const updated = {...current, [key]: value};
    return await config.set(root, updated);
  } else {
    const current = (await config.get(otherOrgs)) || [{[key]: value}];
    const updated = current.map((o) => {
      if (o && o.organization && o.organization.key === orgKey) {
        return {...o, [key]: value};
      } else {
        return o;
      }
    });
    return await config.set(otherOrgs, updated);
  }
}

async function deleteConfig(config, orgKey) {
  if (orgKey === root) {
    return await config.delete(orgKey);
  } else {
    const current = (await config.get(otherOrgs)) || [];
    const updated = current.filter((o) => !isOrganizationWithKey(orgKey)(o));
    if (!!updated.length) {
      return await config.set(otherOrgs, updated);
    } else {
      return await config.delete(otherOrgs);
    }
  }
}

module.exports = {
  saveConfig,
  deleteConfig,
  loadConfig,
  tab: '\t  - ',
  rootKey: root,
};
