const { matchers } = require('jest-json-schema');
const schema = require('../docs/schema');
const sample01 = require('../samples/fabrikkaConfig-1org-1channel-1chaincode');
const sample02 = require('../samples/fabrikkaConfig-2orgs-2channels-1chaincode');
const docsSample = require('../docs/sample');

expect.extend(matchers);

describe('samples', () => {
  [
    ['sample01', sample01],
    ['sample02', sample02],
    ['docsSample', docsSample],
  ].forEach(([name, json]) => {
    it(`${name} should match schema`, () => {
      expect(json).toMatchSchema(schema);
    });
  });
});

describe('schema', () => {
  it('should validate fabric version', () => {
    const json = { ...docsSample, networkSettings: { ...docsSample.networkSettings, fabricVersion: '1.3.2' } };
    expect(json).not.toMatchSchema(schema);
  });
});
