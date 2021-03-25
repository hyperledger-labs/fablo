/* eslint import/no-unresolved: 0 */
/* eslint import/no-absolute-path: 0 */
const { buildInfo } = require('/fabrica/version.json');

function getBuildInfo() {
  return buildInfo;
}

module.exports = {
  getBuildInfo,
};
