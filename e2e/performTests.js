const { execSync } = require('child_process');
// eslint-disable-next-line import/no-extraneous-dependencies
const { matchers } = require('jest-json-schema');
const schema = require('../docs/schema');

expect.extend(matchers);

const executeCommand = (c, noConsole = false) => {
  const log = (out) => {
    // eslint-disable-next-line no-console
    if (!noConsole) console.log(out);
  };

  log(c);
  const out = execSync(c, { encoding: 'utf-8' });
  log(out);
  return out;
};

const generate = (config, target) => {
  executeCommand(`(rm -rf "${target}" && mkdir -p "${target}" && cd "${target}" && sh ../../../fabrikka.sh generate "../../../${config}")`);
};

const getFiles = (target) => executeCommand(`find ${target}/.fabrikka/* -type f`)
  .split('\n')
  .filter((s) => !!s.length)
  .sort();

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

const testFilesContent = (config, files) => files.forEach((f) => {
  it(`should create proper ${f} from ${config}`, () => {
    const content = executeCommand(`cat ${f}`, true);
    const cleaned = content
      .replace(/FABRIKKA_CONFIG=(.*?)(\n|$)/g, 'FABRIKKA_CONFIG=<absolute path>\n')
      .replace(/CHAINCODES_ROOT=(.*?)(\n|$)/g, 'CHAINCODES_ROOT=<absolute path>\n');
    expect(cleaned).toMatchSnapshot();
  });
});

exports.performTests = (label, sample) => {
  const config = `samples/${sample}`;
  testSchemaMatch(config);

  const target = `e2e/__tmp__/${label}`;
  generate(config, target);

  const files = getFiles(target);
  testFilesExistence(config, files);
  testFilesContent(config, files);
};
