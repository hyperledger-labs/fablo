const got = require('got');
const { repositoryTagsListUrl } = require('./config');

const incrementVersionFragment = (versionFragment) => {
  if (versionFragment.includes('-')) {
    const splitted = versionFragment.split('-');
    return `${+splitted[0] + 100000}-${splitted[1]}`;
  }
  return +versionFragment + 100000;
};

const incrementVersionFragments = (v) => v.split('.').map(incrementVersionFragment).join('.');

const decrementVersionFragment = (incrementedVersionFragment) => {
  if (incrementedVersionFragment.includes('-')) {
    const splitted = incrementedVersionFragment.split('-');
    return `${+splitted[0] - 100000}-${splitted[1]}`;
  }
  return +incrementedVersionFragment - 100000;
};

const decrementVersionFragments = (v) => v.split('.').map(decrementVersionFragment).join('.');

const namedVersionsAsLast = (a, b) => {
  if (/[a-z]/i.test(a) && !/[a-z]/i.test(b)) return -1;
  if (/[a-z]/i.test(b) && !/[a-z]/i.test(a)) return 1;
  if (a.toString() < b.toString()) return -1;
  if (a.toString() > b.toString()) return 1;
  return 0;
};

const sortVersions = (versions) => versions
  .map(incrementVersionFragments)
  .sort(namedVersionsAsLast)
  .map(decrementVersionFragments)
  .reverse();

const version = (v) => ({
  isGreaterOrEqual(v2) {
    const vStd = incrementVersionFragments(v).split('-')[0];
    const v2Std = incrementVersionFragments(v2).split('-')[0];
    return vStd >= v2Std;
  },
});

const getAvailableTags = async () => {
  const params = {
    searchParams: {
      tag_status: 'active',
      page_size: 1024,
    },
  };
  try {
    const versionNames = (await got(repositoryTagsListUrl, params).json()).results
      .filter((v) => v.name !== 'latest')
      .map((tag) => tag.name);
    return sortVersions(versionNames);
  } catch (err) {
    /* eslint no-console: 0 */
    console.log(`Could not check for updates. Url: '${repositoryTagsListUrl}' not available`);
    return [];
  }
};

module.exports = {
  getAvailableTags,
  sortVersions,
  version,
};
