// eslint-disable-next-line import/no-extraneous-dependencies
const { matchers } = require('jest-json-schema');
const schema = require('../docs/schema');
const { TestCommands } = require('./TestCommands');

expect.extend(matchers);

const testSchemaMatch = (config) => {
  it(`should be compliant with schema (${config})`, () => {
    // eslint-disable-next-line global-require,import/no-dynamic-require
    const json = require(`../${config}`);
    expect(json).toMatchSchema(schema);
  });
};

const testFilesExistence = (config, files) => {
  it(`should create proper files from ${config}`, () => {
    expect(files).toMatchSnapshot();
  });
};

const testFilesContent = (commands, config, files) => files.forEach((f) => {
  it(`should create proper ${f} from ${config}`, () => {
    const content = commands.getFileContent(`${commands.relativeRoot}/${f}`);
    const cleaned = content
      .replace(/FABRICA_BUILD=(.*?)(\n|$)/g, 'FABRICA_BUILD=<date with git hash>\n')
      .replace(/FABRICA_CONFIG=(.*?)(\n|$)/g, 'FABRICA_CONFIG=<absolute path>\n')
      .replace(/CHAINCODES_BASE_DIR=(.*?)(\n|$)/g, 'CHAINCODES_BASE_DIR=<absolute path>\n')
      .replace(/COMPOSE_PROJECT_NAME=(.*?)(\n|$)/g, 'COMPOSE_PROJECT_NAME=<name with timestamp>\n');
    expect(cleaned).toMatchSnapshot();
  });
});

exports.performTests = (label, sample) => {
  const config = `samples/${sample}`;
  testSchemaMatch(config);

  const commands = new TestCommands(`e2e/__tmp__/${label}`, '../../..');
  commands.cleanupWorkdir();
  commands.fabricaExec(`generate "${commands.relativeRoot}/${config}"`);

  const files = commands.getFiles();
  testFilesExistence(config, files);
  testFilesContent(commands, config, files);
};
