const { execSync } = require('child_process');
const currentFabricaVersion = require('../package.json').version;

const commandOutput = (status, output) => ({
  status,
  output,
  outputJson: () => JSON.parse(output),
});

const executeCommand = (c, noConsole = false) => {
  // eslint-disable-next-line no-console
  const log = !noConsole ? (out) => console.log(out) : () => {};
  try {
    log(c);
    const output = execSync(c, { encoding: 'utf-8' });
    log(output);
    return commandOutput(0, output);
  } catch (e) {
    const output = (e.output || []).join('');
    // eslint-disable-next-line no-console
    console.error(output);
    return commandOutput(e.status, output);
  }
};

const success = () => expect.objectContaining({ status: 0 });
const failure = () => expect.objectContaining({ status: 1 });

const workdir = './e2e/__tmp__/commands-tests';
const relativeRoot = '../../..';

const fabricaExec = (command) => executeCommand(`cd ${workdir} && ${relativeRoot}/fabrica.sh ${command}`);

const getFiles = () => executeCommand(`find '${workdir}' -type f`)
  .output
  .split('\n')
  .filter((s) => !!s.length)
  .sort();

const getFileContent = (file) => executeCommand(`cat ${file}`);

const cleanupWorkdir = () => {
  execSync(`rm -rf ${workdir} ; mkdir -p ${workdir}`);
};

describe('init', () => {
  beforeEach(cleanupWorkdir);

  it('should `init` simple fabrica config', () => {
    // When
    const commandResult = fabricaExec('init');

    // Then
    expect(commandResult)
      .toEqual(success());
    expect(commandResult)
      .toMatchSnapshot();
    expect(getFiles())
      .toEqual(['./e2e/__tmp__/commands-tests/fabrica-config.json']);
    expect(getFileContent(`${workdir}/fabrica-config.json`))
      .toMatchSnapshot();
  });
});

describe('use', () => {
  beforeEach(cleanupWorkdir);

  it('should display versions', () => {
    // When
    const commandResult = fabricaExec('use');

    // Then
    expect(commandResult).toEqual(success());
    expect(commandResult.output).toContain('0.0.1');
    expect(commandResult.output).toContain(`${currentFabricaVersion} <== current`);
    expect(getFiles()).toEqual([]);
  });
});

describe('validate', () => {
  beforeEach(cleanupWorkdir);

  it('should validate default config', () => {
    // Given
    fabricaExec('init');

    // When
    const commandResult = fabricaExec('validate');

    // Then
    expect(commandResult).toEqual(success());
    expect(commandResult).toMatchSnapshot();
    expect(getFiles()).toEqual(['./e2e/__tmp__/commands-tests/fabrica-config.json']);
  });

  it('should validate custom config', () => {
    // Given
    const fabricaConfig = `${relativeRoot}/samples/fabricaConfig-2orgs-2channels-2chaincodes-tls-raft.json`;

    // When
    const commandResult = fabricaExec(`validate ${fabricaConfig}`);

    // Then
    expect(commandResult).toEqual(success());
    expect(commandResult).toMatchSnapshot();
    expect(getFiles()).toEqual([]);
  });

  it('should fail to validate if config file is missing', () => {
    const commandResult = fabricaExec('validate');

    // Then
    expect(commandResult).toEqual(failure());
    expect(commandResult).toMatchSnapshot();
    expect(getFiles()).toEqual([]);
  });
});

describe('version', () => {
  it('should print version information', () => {
    // When
    const commandResult = fabricaExec('version');

    // Then
    expect(commandResult).toEqual(success());
    expect(commandResult.outputJson()).toEqual(expect.objectContaining({
      version: currentFabricaVersion,
      build: expect.stringMatching(/.*/),
    }));
  });

  it('should print verbose version information', () => {
    // When
    const commandResult1 = fabricaExec('version -v');
    const commandResult2 = fabricaExec('version --verbose');

    // Then
    expect(commandResult1).toEqual(success());
    expect(commandResult1.outputJson()).toEqual(expect.objectContaining({
      version: currentFabricaVersion,
      build: expect.stringMatching(/.*/),
      supported: expect.objectContaining({
        fabricaVersions: expect.stringMatching(/.*/),
        hyperledgerFabricVersions: expect.anything(),
      }),
    }));

    expect(commandResult1.status).toEqual(commandResult2.status);
    expect(commandResult1.output).toEqual(commandResult2.output);
  });
});

// TODO describe(printConfig)
