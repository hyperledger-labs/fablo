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
    const response = await got(repositoryTagsListUrl, params).json();
    return response.results
        .filter((version) => version.name !== 'latest')
        .map(tag => tag.name);
  } catch (err) {
    /* eslint no-console: 0 */
    console.log(`Could not check for updates. Url: '${repositoryTagsListUrl}' not available`);
    return [];
  }
}

function sortVersions(versionsList) {
  console.log(versionsList)
  return versionsList
    .map((a) => a.split('.').map((n) => +n + 100000).join('.')).sort()
    .map((a) => a.split('.').map((n) => +n - 100000).join('.'))
    .reverse();
}

module.exports = {
  getAvailableTags,
  sortVersions,
};
