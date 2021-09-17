import { execSync } from "child_process";

interface CommandOutput {
  status: number;
  output: string;
  outputJson: () => Record<string, unknown>;
}

const commandOutput = (status: number, output: string): CommandOutput => ({
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

const executeCommand = (c: string, noConsole = false): CommandOutput => {
  // eslint-disable-next-line no-console
  const log = !noConsole ? (out: string) => console.log(out) : () => ({});
  try {
    log(c);
    const output = execSync(c, { encoding: "utf-8" });
    log(output);
    return commandOutput(0, output);
  } catch (e) {
    const output = (e.output || []).join("");
    // eslint-disable-next-line no-console
    console.error(`Error executing command ${c}`, e, output);
    return commandOutput(e.status, output);
  }
};

class TestCommands {
  static success = (): unknown => expect.objectContaining({ status: 0 });

  static failure = (): unknown => expect.objectContaining({ status: 1 });

  readonly relativeRoot: string;

  constructor(readonly workdir: string) {
    this.relativeRoot = workdir.replace(/[^\/]+/g, "..");
  }

  execute(command: string): CommandOutput {
    return executeCommand(command);
  }

  fabloExec(command: string, noConsole = false): CommandOutput {
    return executeCommand(`cd ${this.workdir} && ${this.relativeRoot}/fablo.sh ${command}`, noConsole);
  }

  getFiles(dir?: string): string[] {
    return executeCommand(`find ${dir || this.workdir} -type f`)
      .output.split("\n")
      .filter((s) => !!s.length)
      .sort();
  }

  getFileContent(file: string): string {
    return executeCommand(`cat "${this.workdir}/${file}"`, true).output;
  }

  cleanupWorkdir(): void {
    execSync(`rm -rf ${this.workdir} ; mkdir -p ${this.workdir}`);
  }
}

export default TestCommands;
export { CommandOutput };
