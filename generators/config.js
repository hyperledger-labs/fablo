const repositoryName = 'softwaremill/fabrica';
const repositoryTagsListUrl = `https://registry.hub.docker.com/v2/repositories/${repositoryName}/tags`;

const { version: fabricaVersion } = require('../package.json');
const schema = require('../docs/schema.json');
const { version } = require('./repositoryUtils');

const supportedVersionPrefix = `${fabricaVersion.split('.').slice(0, 2).join('.')}.`;

const getVersionFromSchemaUrl = (url) => {
  const matches = (url || '').match(/\d+\.\d+\.\d+/g);
  return (matches && matches.length) > 0 ? matches[0] : fabricaVersion;
};

const isFabricaVersionSupported = (versionName) => versionName.startsWith(supportedVersionPrefix);

const supportedFabricVersions = schema.properties.networkSettings.properties.fabricVersion.enum;

const versionsSupportingRaft = supportedFabricVersions.filter((v) => version(v).isGreaterOrEqual('1.4.3'));

const splashScreen = () => `${'Fabrica is powered by :\n'
  + ' _____        __ _                         ___  ____ _ _ \n'
  + '/  ___|      / _| |                        |  \\/  (_) | |\n'
  + '\\ `--.  ___ | |_| |___      ____ _ _ __ ___| .  . |_| | |\n'
  + ' `--. \\/ _ \\|  _| __\\ \\ /\\ / / _` | \'__/ _ \\ |\\/| | | | |\n'
  + '/\\__/ / (_) | | | |_ \\ V  V / (_| | | |  __/ |  | | | | |\n'
  + '\\____/ \\___/|_|  \\__| \\_/\\_/ \\__,_|_|  \\___\\_|  |_/_|_|_|\n'
  + '=========================================================== v: '}${fabricaVersion}`;

module.exports = {
  repositoryTagsListUrl,
  splashScreen,
  fabricaVersion,
  supportedFabricVersions,
  versionsSupportingRaft,
  getVersionFromSchemaUrl,
  isFabricaVersionSupported,
  supportedVersionPrefix,
};
