const { execSync } = require('child_process');
const { matchers } = require('jest-json-schema');

expect.extend(matchers);

const executeCommand = (c) => execSync(c, { encoding: 'utf-8' });

const getJson = (path) => JSON.parse(executeCommand(`cat "${path}"`));

const verifyJson = (path, schemaJson) => {
  it(`should be obeyed by ${path}`, () => {
    expect(getJson(path)).toMatchSchema(schemaJson);
  });
};

const sample01 = 'samples/fabrikkaConfig-1org-1channel-1chaincode.json';
const sample02 = 'samples/fabrikkaConfig-2orgs-2channels-1chaincode.json';
const docsSample = 'docs/sample.json';

const schema = 'docs/schema.json';

describe(schema, () => {
  const schemaJson = getJson(schema);
  verifyJson(sample01, schemaJson);
  verifyJson(sample02, schemaJson);
  verifyJson(docsSample, schemaJson);
});
