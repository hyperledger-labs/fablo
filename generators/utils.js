module.exports = {
  updateNamespace,
};

async function updateNamespace(config, orgNamespace, key, value) {
  const current = await config.get(orgNamespace);
  return await config.set(orgNamespace, {...current, [key]: value});
}
