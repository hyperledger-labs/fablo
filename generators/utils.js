module.exports = {
  updateNamespace,
  getNamespace,
};

function getNamespace(options) {
  return !!(options || {}).isRoot ? 'root' : 'orgs';
}

async function updateNamespace(config, namespace, key, value) {
  const current = await config.get(namespace);
  return await config.set(namespace, {...current, [key]: value});
}
