const { repositoryTagsListUrl } = require('../config');
const got = require('got');

async function getAvailableTags() {
    const params = {
        searchParams: {
            tag_status: 'active',
            page_size: 1024,
        },
    };
    try {
        return await got(repositoryTagsListUrl, params).json();
    } catch(err) {
        console.log(`Could not check for updates. Url: '${repositoryTagsListUrl}' not available`)
        return {results: []};
    }

}

module.exports = {
    getAvailableTags,
};
