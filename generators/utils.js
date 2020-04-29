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
    const updated = { ...current, [key]: value };
    return config.set(root, updated);
  }
  const current = (await config.get(otherOrgs)) || [{ [key]: value }];
  const updated = current.map((o) => {
    const theSameKey = o && o.organization && o.organization.key === orgKey;
    return theSameKey ? { ...o, [key]: value } : o;
  });
  return config.set(otherOrgs, updated);
}

async function deleteConfig(config, orgKey) {
  if (orgKey === root) {
    return config.delete(orgKey);
  }
  const current = (await config.get(otherOrgs)) || [];
  const updated = current.filter((o) => !isOrganizationWithKey(orgKey)(o));
  if (updated.length) {
    return config.set(otherOrgs, updated);
  }
  return config.delete(otherOrgs);
}

function splashScreen() {
  return 'Fabrikka is powered by :\n'
      + ' _____        __ _                         ___  ____ _ _ \n'
      + '/  ___|      / _| |                        |  \\/  (_) | |\n'
      + '\\ `--.  ___ | |_| |___      ____ _ _ __ ___| .  . |_| | |\n'
      + ' `--. \\/ _ \\|  _| __\\ \\ /\\ / / _` | \'__/ _ \\ |\\/| | | | |\n'
      + '/\\__/ / (_) | | | |_ \\ V  V / (_| | | |  __/ |  | | | | |\n'
      + '\\____/ \\___/|_|  \\__| \\_/\\_/ \\__,_|_|  \\___\\_|  |_/_|_|_|\n'
      + '=========================================================== v: alpha-0.0.1';
}

module.exports = {
  splashScreen,
  saveConfig,
  deleteConfig,
  loadConfig,
  tab: '\t  - ',
  rootKey: root,
  otherOrgsKey: otherOrgs,
};
