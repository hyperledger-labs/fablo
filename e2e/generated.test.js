const { execSync } = require('child_process');

const executeCommand = (c) => execSync(c, { encoding: 'utf-8' });

const dir01 = 'e2e/__tmp__/sample-01';
const dir02 = 'e2e/__tmp__/sample-02';
const dir03 = 'e2e/__tmp__/sample-03';
const dir04 = 'e2e/__tmp__/sample-04';

const getFiles = (dir) => executeCommand(`find ${dir}/* -type f`)
  .split('\n')
  .filter((s) => !!s.length)
  .sort();

const testFilesExistence = (files) => {
  it('should create proper files', () => {
    expect(files).toMatchSnapshot();
  });
};

const testFilesContent = (files) => files.forEach((f) => {
  it(`should create proper ${f}`, () => {
    expect(executeCommand(`cat ${f}`)).toMatchSnapshot();
  });
});

describe(dir01, () => {
  const files = getFiles(dir01);
  testFilesExistence(files);
  testFilesContent(files);
});

describe(dir02, () => {
  const files = getFiles(dir02);
  testFilesExistence(files);
  testFilesContent(files);
});

describe(dir03, () => {
  const files = getFiles(dir03);
  testFilesExistence(files);
  testFilesContent(files);
});

describe(dir04, () => {
  const files = getFiles(dir04);
  testFilesExistence(files);
  testFilesContent(files);
});
