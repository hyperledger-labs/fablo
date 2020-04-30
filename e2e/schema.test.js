const { execSync } = require('child_process');
const { matchers } = require('jest-json-schema');

expect.extend(matchers);

const executeCommand = (c) => execSync(c, { encoding: 'utf-8' });

const sample01 = 'samples/fabrikkaConfig-1org-1channel-1chaincode.json';
const sample02 = 'samples/fabrikkaConfig-2orgs-2channels-1chaincode.json';

const schema = 'docs/schema.json';

const getJson = (path) => JSON.parse(executeCommand(`cat "${path}"`));

describe(schema, () => {
  const schemaJson = getJson(schema);

  it(`should be obeyed by ${sample01}`, () => {
    expect(getJson(sample01)).toMatchSchema(schemaJson);
  });

  it(`should be obeyed by ${sample02}`, () => {
    expect(getJson(sample02)).toMatchSchema(schemaJson);
  });
});
