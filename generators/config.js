const fabrikkaVersion = ['alpha-0.0.1'];

const supportedFabricVersions = [
    '1.3.0', '1.4.0', '1.4.1', '1.4.2', '1.4.3', '1.4.4', '1.4.5', '1.4.6', '1.4.7', '1.4.8',
    `2.0.1`, `2.1.0`, `2.2.0`, `2.2.1`
];
const versionsSupportingRaft = [
    '1.4.1', '1.4.2', '1.4.3', '1.4.4', '1.4.5', '1.4.6', '1.4.7', '1.4.8',
    `2.0.1`, `2.1.0`, `2.2.0`, `2.2.1`
];
const supportedFabrikkaVersions = ['alpha-0.0.1'];

function splashScreen() {
  return `${'Fabrikka is powered by :\n'
        + ' _____        __ _                         ___  ____ _ _ \n'
        + '/  ___|      / _| |                        |  \\/  (_) | |\n'
        + '\\ `--.  ___ | |_| |___      ____ _ _ __ ___| .  . |_| | |\n'
        + ' `--. \\/ _ \\|  _| __\\ \\ /\\ / / _` | \'__/ _ \\ |\\/| | | | |\n'
        + '/\\__/ / (_) | | | |_ \\ V  V / (_| | | |  __/ |  | | | | |\n'
        + '\\____/ \\___/|_|  \\__| \\_/\\_/ \\__,_|_|  \\___\\_|  |_/_|_|_|\n'
        + '=========================================================== v: '}${fabrikkaVersion}`;
}

module.exports = {
  splashScreen,
  supportedFabricVersions,
  versionsSupportingRaft,
  supportedFabrikkaVersions,
};
