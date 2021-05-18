import * as Generator from "yeoman-generator";
import { basicInfo, fullInfo } from "./buildUtil";

export default class VersionGenerator extends Generator {
  constructor(args: string[], opts: Generator.GeneratorOptions) {
    super(args, opts);
    this.option("verbose", {
      type: Boolean,
      alias: "v",
    });
  }

  async printVersion(): Promise<void> {
    if (typeof this.options.verbose !== "undefined") {
      this.log(JSON.stringify(fullInfo(), null, 2));
    } else {
      this.log(JSON.stringify(basicInfo(), null, 2));
    }
  }
}
