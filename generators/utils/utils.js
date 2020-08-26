function getFullPathOf(configFile, cwd) {
  const currentPath = cwd;
  return `${currentPath}/${configFile}`;
}

function groupBy(list, keyGetter) {
  const map = new Map();
  list.forEach((item) => {
    const key = keyGetter(item);
    const collection = map.get(key);
    if (!collection) {
      map.set(key, [item]);
    } else {
      collection.push(item);
    }
  });
  return map;
}

module.exports = {
  getFullPathOf,
  groupBy,
};
