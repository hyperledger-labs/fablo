const repositoryName = 'softwaremill/fabrica';
const repositoryTagsListUrl = `https://registry.hub.docker.com/v2/repositories/${repositoryName}/tags`;

const { version } = require('../package.json');

const supportedVersionPrefix = `${version.split('.').slice(0, 2).join('.')}.`;

const getVersionFromSchemaUrl = (url) => {
  const matches = (url || '').match(/\d+\.\d+\.\d+/g);
  return (matches && matches.length) > 0 ? matches[0] : version;
};

const isFabricaVersionSupported = (versionName) => versionName.startsWith(supportedVersionPrefix);

const supportedFabricVersions = [
  '1.3.0', '1.4.0', '1.4.1', '1.4.2', '1.4.3', '1.4.4', '1.4.5', '1.4.6', '1.4.7', '1.4.8',
];

const versionsSupportingRaft = [
  '1.4.1', '1.4.2', '1.4.3', '1.4.4', '1.4.5', '1.4.6', '1.4.7', '1.4.8',
];

const splashScreen = () => `${'Fabrica is powered by :\n'
  + ' _____        __ _                         ___  ____ _ _ \n'
  + '/  ___|      / _| |                        |  \\/  (_) | |\n'
  + '\\ `--.  ___ | |_| |___      ____ _ _ __ ___| .  . |_| | |\n'
  + ' `--. \\/ _ \\|  _| __\\ \\ /\\ / / _` | \'__/ _ \\ |\\/| | | | |\n'
  + '/\\__/ / (_) | | | |_ \\ V  V / (_| | | |  __/ |  | | | | |\n'
  + '\\____/ \\___/|_|  \\__| \\_/\\_/ \\__,_|_|  \\___\\_|  |_/_|_|_|\n'
  + '=========================================================== v: '}${version}`;

module.exports = {
  repositoryTagsListUrl,
  splashScreen,
  version,
  supportedFabricVersions,
  versionsSupportingRaft,
  getVersionFromSchemaUrl,
  isFabricaVersionSupported,
  supportedVersionPrefix,
};
