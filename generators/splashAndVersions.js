const { version } = require('../package.json');
const schema = require('../docs/schema.json');

const supportedVersionPrefix = `${version.split('.').slice(0, 2).join('.')}.`;

const getVersionFromSchemaUrl = (url) => {
  const matches = (url || '').match(/\d+\.\d+\.\d+/g);
  return (matches && matches.length) > 0 ? matches[0] : version;
};

const isFabricaVersionSupported = (versionName) => versionName.startsWith(supportedVersionPrefix);

const supportedFabricVersions = schema.properties.networkSettings.properties.fabricVersion.enum;

const versionsSupportingRaft = supportedFabricVersions.filter((v) => v !== '1.3.0' && v !== '1.4.0');

const splashScreen = () => `${'Fabrica is powered by :\n'
  + ' _____        __ _                         ___  ____ _ _ \n'
  + '/  ___|      / _| |                        |  \\/  (_) | |\n'
  + '\\ `--.  ___ | |_| |___      ____ _ _ __ ___| .  . |_| | |\n'
  + ' `--. \\/ _ \\|  _| __\\ \\ /\\ / / _` | \'__/ _ \\ |\\/| | | | |\n'
  + '/\\__/ / (_) | | | |_ \\ V  V / (_| | | |  __/ |  | | | | |\n'
  + '\\____/ \\___/|_|  \\__| \\_/\\_/ \\__,_|_|  \\___\\_|  |_/_|_|_|\n'
  + '=========================================================== v: '}${version}`;

module.exports = {
  splashScreen,
  version,
  supportedFabricVersions,
  versionsSupportingRaft,
  getVersionFromSchemaUrl,
  isFabricaVersionSupported,
  supportedVersionPrefix,
};
