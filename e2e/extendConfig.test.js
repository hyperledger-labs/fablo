const { TestCommands } = require('./TestCommands');
const ExtendConfigGenerator = require('../generators/extend-config');

const commands = new TestCommands('./e2e/__tmp__/extend-config-tests', '../../..');

describe('extend config', () => {
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
      // given
      // eslint-disable-next-line global-require,import/no-dynamic-require
      const json = require(`../${file}`);

      // when
      const extended = ExtendConfigGenerator.extendJsonConfig(json);

      // then
      expect(extended).toMatchSnapshot();
    });
  });
});
