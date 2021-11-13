const { getVersionFromSchemaUrl } = require('./config');
const packageJson = require('../package.json');

it('should get version from schema URL', () => {
  const url = 'https://github.com/softwaremill/fabrica/releases/download/0.0.1/schema.json';
  const version = getVersionFromSchemaUrl(url);
  expect(version).toEqual('0.0.1');
});

it('should get current version in case of missing schema URL', () => {
  const version = getVersionFromSchemaUrl(undefined);
  expect(version).toEqual(packageJson.version);
});
