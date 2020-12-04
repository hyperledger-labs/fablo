const got = require('got');
const { repositoryTagsListUrl } = require('./config');

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
        .map(tag => tag.name);
    return sortVersions(versionNames)
  } catch (err) {
    /* eslint no-console: 0 */
    console.log(`Could not check for updates. Url: '${repositoryTagsListUrl}' not available`);
    return [];
  }
}

function sortVersions(versions) {
  return versions
    .map((a) => a.split('.').map((n) => +n + 100000).join('.')).sort()
    .map((a) => a.split('.').map((n) => +n - 100000).join('.'))
    .reverse();
}

module.exports = {
  getAvailableTags,
  sortVersions
};
