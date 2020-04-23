const { execSync } = require('child_process');

const executeCommand = (c) => execSync(c, { encoding: 'utf-8' });

const configFileName = 'sample-01.json';
const tmpDirPath = `e2e/__tmp__/${configFileName}`;

describe(configFileName, () => {
  const listFilesOutput = executeCommand(`find ${tmpDirPath}/* -type f`);
  const files = listFilesOutput.split('\n').filter((s) => !!s.length);

  it('should create proper files', () => {
    expect(listFilesOutput).toMatchSnapshot();
  });

  files.forEach((f) => {
    it(`should create proper ${f}`, () => {
      expect(executeCommand(`cat ${f}`)).toMatchSnapshot();
    });
  });
});
