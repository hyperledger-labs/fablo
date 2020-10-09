const { execSync } = require('child_process');
// eslint-disable-next-line import/no-extraneous-dependencies
const { matchers } = require('jest-json-schema');
const schema = require('../docs/schema');

expect.extend(matchers);

const executeCommand = (c) => {
  // eslint-disable-next-line no-console
  console.log(c);
  const out = execSync(c, { encoding: 'utf-8' });

  // eslint-disable-next-line no-console
  console.log(out);
  return out;
};

const generate = (config, target) => {
  executeCommand(`sh "docker-generate.sh" "${config}" "${target}"`);
};

const getFiles = (target) => executeCommand(`find ${target}/* -type f`)
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
    expect(executeCommand(`cat ${f}`)).toMatchSnapshot();
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
