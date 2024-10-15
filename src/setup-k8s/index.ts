import * as Generator from "yeoman-generator";
import * as config from "../config";
import { getBuildInfo } from "../version/buildUtil";
import parseFabloConfig from "../utils/parseFabloConfig";
import { Capabilities, FabloConfigExtended, HooksConfig, Global, OrgConfig } from "../types/FabloConfigExtended";
import { extendConfig } from "../extend-config/";

const ValidateGeneratorPath = require.resolve("../validate");

export default class SetupDockerGenerator extends Generator {
  constructor(args: string[], opts: Generator.GeneratorOptions) {
    super(args, opts);
    this.argument("fabloConfig", {
      type: String,
      optional: true,
      description: "Fablo config file path",
      default: "../../network/fablo-config.json",
    });

    this.composeWith(ValidateGeneratorPath, { arguments: [this.options.fabloConfig] });
  }

  async writing(): Promise<void> {
    const fabloConfigPath = `${this.env.cwd}/${this.options.fabloConfig}`;
    const json = parseFabloConfig(this.fs.read(fabloConfigPath));
    const config = extendConfig(json);
    const { global, orgs } = config;

    const dateString = new Date()
      .toISOString()
      .substring(0, 16)
      .replace(/[^0-9]+/g, "");
    const composeNetworkName = `fablo_network_${dateString}`;

    console.log(`Used network config: ${fabloConfigPath}`);
    console.log(`Fabric version is: ${global.fabricVersion}`);

    this._copyGitIgnore();

    // ======= fabric-k8s ===========================================================
    this._copyEnvFile(global, orgs, composeNetworkName);

    // ======= scripts ==================================================================
    // this._copyCommandsGeneratedScript(config);
    this._copyCommandsGeneratedScript(config);
    this._copyUtilityScripts(config.global.capabilities);

    // ======= hooks ====================================================================
    this._copyHooks(config.hooks);

    this.on("end", () => {
      console.log("Done & done !!! Try the network out: ");
      console.log("-> fablo up - to start network");
      console.log("-> fablo help - to view all commands");
    });
  }

  _copyGitIgnore(): void {
    this.fs.copyTpl(this.templatePath("fabric-config/.gitignore"), this.destinationPath("fabric-config/.gitignore"));
  }

  _copyEnvFile(global: Global, orgsTransformed: OrgConfig[], composeNetworkName: string): void {
    const settings = {
      composeNetworkName,
      fabricCaVersion: global.fabricCaVersion,
      global,
      orgs: orgsTransformed,
      paths: global.paths,
      fabloVersion: config.fabloVersion,
      fabloBuild: getBuildInfo(),
      fabloRestVersion: "0.1.2",
      hyperledgerExplorerVersion: "1.1.8",
      fabricCouchDbVersion: "0.4.18",
      couchDbVersion: "3.1",
      fabricCaPostgresVersion: "14",
    };
    this.fs.copyTpl(this.templatePath("fabric-k8s/.env"), this.destinationPath("fabric-k8s/.env"), settings);
  }

  _copyCommandsGeneratedScript(config: FabloConfigExtended): void {
    this.fs.copyTpl(
      this.templatePath("fabric-k8s/scripts/base-functions.sh"),
      this.destinationPath("fabric-k8s/scripts/base-functions.sh"),
      config,
    );
  }
  _copyUtilityScripts(capabilities: Capabilities): void {
    this.fs.copyTpl(this.templatePath("fabric-k8s.sh"), this.destinationPath("fabric-k8s.sh"));
    this.fs.copyTpl(
      this.templatePath("fabric-k8s/scripts/base-help.sh"),
      this.destinationPath("fabric-k8s/scripts/base-help.sh"),
    );

    this.fs.copyTpl(
      this.templatePath("fabric-k8s/scripts/util.sh"),
      this.destinationPath("fabric-k8s/scripts/util.sh"),
    );

    this.fs.copyTpl(
      this.templatePath(`fabric-k8s/scripts/chaincode-functions.sh`),
      this.destinationPath("fabric-k8s/scripts/chaincode-functions.sh"),
    );

    this.fs.copyTpl(
      this.templatePath(`fabric-k8s/scripts/chaincode-functions-${capabilities.isV2 ? "v2" : "v1.4"}.sh`),
      this.destinationPath("fabric-k8s/scripts/chaincode-functions.sh"),
    );
  }

  _copyHooks(hooks: HooksConfig): void {
    this.fs.copyTpl(this.templatePath("hooks/post-generate.sh"), this.destinationPath("hooks/post-generate.sh"), {
      hooks,
    });
  }
}
