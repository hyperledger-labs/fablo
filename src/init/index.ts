import * as Generator from "yeoman-generator";
import * as chalk from "chalk";
import parseFabloConfig from "../utils/parseFabloConfig";

export default class InitGenerator extends Generator {
  constructor(readonly args: string[], opts: Generator.GeneratorOptions) {
    super(args, opts);
  }

  async copySampleConfig(): Promise<void> {
    let fabloConfigJson = parseFabloConfig(this.fs.read(this.templatePath("fablo-config.json")));

    const shouldInitWithNodeChaincode = this.args.length && this.args.find((v) => v === "node");
    if (shouldInitWithNodeChaincode) {
      this.log("Creating sample Node.js chaincode");
      this.fs.copy(this.templatePath("chaincodes"), this.destinationPath("chaincodes"));
    } else {
      fabloConfigJson = { ...fabloConfigJson, chaincodes: [] };
    }

    const shouldAddFabloRest = this.args.length && this.args.find((v) => v === "rest");
    if (shouldAddFabloRest) {
      const orgs = fabloConfigJson.orgs.map((org) => ({ ...org, tools: { fabloRest: true } }));
      fabloConfigJson = { ...fabloConfigJson, orgs };
    } else {
      const orgs = fabloConfigJson.orgs.map((org) => ({ ...org, tools: {} }));
      fabloConfigJson = { ...fabloConfigJson, orgs };
    }

    this.fs.write(this.destinationPath("fablo-config.json"), JSON.stringify(fabloConfigJson, undefined, 2));

    this.on("end", () => {
      this.log("===========================================================");
      this.log(chalk.bold("Sample config file created! :)"));
      this.log("You can start your network with 'fablo up' command");
      this.log("===========================================================");
    });
  }
}
