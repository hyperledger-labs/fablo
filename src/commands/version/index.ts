import { Flags, Command } from "@oclif/core";
import { basicInfo, fullInfo } from "../../version/buildUtil";

export default class Version extends Command {
  static override description = "Print Fablo version information";

  static override flags = {
    verbose: Flags.boolean({
      char: "v",
      description: "Show verbose version information",
    }),
  };

  public async run(): Promise<void> {
    const { flags } = await this.parse(Version);

    if (flags.verbose) {
      this.log(JSON.stringify(fullInfo(), null, 2));
    } else {
      this.log(JSON.stringify(basicInfo(), null, 2));
    }
  }
}

