const { matchers } = require('jest-json-schema');
const { TestCommands } = require('./TestCommands');
const schema = require('../docs/schema');

expect.extend(matchers);

const commands = new TestCommands('./e2e/__tmp__/schema-files-match-tests', '../../..');

describe('schema files match', () => {
  beforeEach(() => commands.cleanupWorkdir());

  beforeAll(() => {
    process.env.FABRICA_CONFIG = '<absolute path>';
    process.env.CHAINCODES_BASE_DIR = '<absolute path>';
  });

  afterAll(() => {
    delete process.env.FABRICA_CONFIG;
    delete process.env.CHAINCODES_BASE_DIR;
  });

  const files = commands.getFiles('samples/*.json');

  files.forEach((file) => {
    it(file, () => {
      // eslint-disable-next-line global-require,import/no-dynamic-require
      const json = require(`../${file}`);
      expect(json).toMatchSchema(schema);
    });
  });
});
