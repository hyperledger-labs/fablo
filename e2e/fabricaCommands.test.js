const { execSync } = require('child_process');

const executeCommand = (c, noConsole = false) => {
  // eslint-disable-next-line no-console
  const log = !noConsole ? (out) => console.log(out) : () => {};
  try {
    log(c);
    const output = execSync(c, { encoding: 'utf-8' });
    log(output);
    return { status: 0, output };
  } catch (e) {
    const output = (e.output || []).join('');
    // eslint-disable-next-line no-console
    console.error(output);
    return { status: e.status, output };
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

  it('should init simple fabrica config', () => {
    // When
    const commandResult = fabricaExec('init');

    // Then
    expect(commandResult).toEqual(success());
    expect(commandResult.output).toContain('Sample config file created! :)');
    expect(commandResult.output).toContain(
      'Chaincode directory is \'./chaincodes/chaincode-kv-node\'.\nIf it\'s empty your network won\'t run entirely.',
    );

    expect(getFiles()).toEqual(['./e2e/__tmp__/commands-tests/fabrica-config.json']);
    expect(getFileContent(`${workdir}/fabrica-config.json`)).toMatchSnapshot();
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
    expect(commandResult.output).toContain('<== current');
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
    expect(commandResult.output).toContain('Validation errors count: 0');
    expect(commandResult.output).toContain('Validation warnings count: 0');
    expect(getFiles()).toEqual(['./e2e/__tmp__/commands-tests/fabrica-config.json']);
  });

  it('should validate custom config', () => {
    // Given
    const fabricaConfig = `${relativeRoot}/samples/fabricaConfig-2orgs-2channels-2chaincodes-tls-raft.json`;

    // When
    const commandResult = fabricaExec(`validate ${fabricaConfig}`);

    // Then
    expect(commandResult).toEqual(success());
    expect(commandResult.output).toContain('Validation errors count: 0');
    expect(commandResult.output).toContain('Validation warnings count: 0');
    expect(getFiles()).toEqual([]);
  });

  it('should fail to validate if config file is missing', () => {
    const commandResult = fabricaExec('validate');

    // Then
    expect(commandResult).toEqual(failure());
    expect(commandResult.output).toContain('commands-tests/fabrica-config.json does not exist');
    expect(getFiles()).toEqual([]);
  });
});

// TODO describe(printConfig)
