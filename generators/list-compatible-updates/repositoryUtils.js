const got = require('got');
const { repositoryTagsListUrl } = require('../config');

async function getAvailableTags() {
  const params = {
    searchParams: {
      tag_status: 'active',
      page_size: 1024,
    },
  };
  try {
    const response = await got(repositoryTagsListUrl, params).json();
    return response.results.filter((version) => version.name !== 'latest');
  } catch (err) {
    /* eslint no-console: 0 */
    console.log(`Could not check for updates. Url: '${repositoryTagsListUrl}' not available`);
    return [];
  }
}

module.exports = {
  getAvailableTags,
};
