const { execSync } = require('child_process');

const commandOutput = (status, output) => ({
  status,
  output,
  outputJson() {
    try {
      return JSON.parse(output);
    } catch (e) {
      // eslint-disable-next-line no-console
      console.error(e);
      // eslint-disable-next-line no-console
      console.error(output);
      throw e;
    }
  },
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

class TestCommands {
  constructor(workdir, relativeRoot) {
    this.workdir = workdir;
    this.relativeRoot = relativeRoot;
  }

  execute(command) {
    return executeCommand(command);
  }

  fabricaExec(command) {
    return executeCommand(`cd ${this.workdir} && ${this.relativeRoot}/fabrica.sh ${command}`);
  }

  getFiles() {
    return executeCommand(`find '${this.workdir}' -type f`)
      .output
      .split('\n')
      .filter((s) => !!s.length)
      .sort();
  }

  getFileContent(file) {
    return executeCommand(`cat "${this.workdir}/${file}"`, true).output;
  }

  cleanupWorkdir() {
    return execSync(`rm -rf ${this.workdir} ; mkdir -p ${this.workdir}`);
  }
}

TestCommands.success = () => expect.objectContaining({ status: 0 });

TestCommands.failure = () => expect.objectContaining({ status: 1 });

exports.TestCommands = TestCommands;
