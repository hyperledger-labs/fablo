const got = require('got');

const repositoryName = 'softwaremill/fabrica';
const repositoryTagsListUrl = `https://registry.hub.docker.com/v2/repositories/${repositoryName}/tags`;

const incrementVersionFragments = (versionFragment) => {
  if (versionFragment.includes('-')) {
    const splitted = versionFragment.split('-');
    return `${+splitted[0] + 100000}-${splitted[1]}`;
  }
  return +versionFragment + 100000;
};

const decrementVersionFragments = (incrementedVersionFragment) => {
  if (incrementedVersionFragment.includes('-')) {
    const splitted = incrementedVersionFragment.split('-');
    return `${+splitted[0] - 100000}-${splitted[1]}`;
  }
  return +incrementedVersionFragment - 100000;
};

const namedVersionsAsLast = (a, b) => {
  if (/[a-z]/i.test(a) && !/[a-z]/i.test(b)) return -1;
  if (/[a-z]/i.test(b) && !/[a-z]/i.test(a)) return 1;
  if (a.toString() < b.toString()) return -1;
  if (a.toString() > b.toString()) return 1;
  return 0;
};

function sortVersions(versions) {
  return versions
    .map((a) => a.split('.').map(incrementVersionFragments).join('.')).sort(namedVersionsAsLast)
    .map((a) => a.split('.').map(decrementVersionFragments).join('.'))
    .reverse();
}

async function getAvailableTags() {
  const params = {
    searchParams: {
      tag_status: 'active',
      page_size: 1024,
    },
  };
  try {
    const versionNames = (await got(repositoryTagsListUrl, params).json()).results
      .filter((version) => version.name !== 'latest')
      .map((tag) => tag.name);
    return sortVersions(versionNames);
  } catch (err) {
    /* eslint no-console: 0 */
    console.log(`Could not check for updates. Url: '${repositoryTagsListUrl}' not available`);
    return [];
  }
}

module.exports = {
  getAvailableTags,
  sortVersions,
};
