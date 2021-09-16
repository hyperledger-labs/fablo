import * as Generator from "yeoman-generator";
import * as chalk from "chalk";
import parseFabloConfig from "../utils/parseFabloConfig";

export default class InitGenerator extends Generator {
  constructor(readonly args: string[], opts: Generator.GeneratorOptions) {
    super(args, opts);
  }

  async copySampleConfig(): Promise<void> {
    if (this.args.length && this.args[0] === "node") {
      this.fs.copy(this.templatePath(), this.destinationPath());
    } else {
      const content = this.fs.read(this.templatePath("fablo-config.json"));
      const json = parseFabloConfig(content);
      this.fs.write(
        this.destinationPath("fablo-config.json"),
        JSON.stringify({ ...json, chaincodes: [] }, undefined, 2),
      );
    }

    this.on("end", () => {
      this.log("===========================================================");
      this.log(chalk.bold("Sample config file created! :)"));
      this.log("You can start your network with 'fablo up' command");
      this.log("===========================================================");
    });
  }
}
