const { execSync } = require('child_process');

const executeCommand = (c) => execSync(c, { encoding: 'utf-8' });

const tmpDirPath = 'e2e/__tmp__/01';
const configFileName = 'sample-01.json';
const configFilePath = `e2e/${configFileName}`;

describe(configFileName, () => {
  // cleanup
  executeCommand(`mkdir -p ${tmpDirPath} && rm -rf ${tmpDirPath}/* && cp ${configFilePath} ${tmpDirPath}/`);

  // generate files
  executeCommand(`cd ${tmpDirPath} && yo fabric-network:setup-compose ${configFileName}`);

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
