import * as Generator from "yeoman-generator";
import * as config from "../config";
import { getBuildInfo } from "../version/buildUtil";
import parseFabloConfig from "../utils/parseFabloConfig";
import {
  Capabilities,
  ChaincodeConfig,
  FabloConfigExtended,
  NetworkSettings,
  OrdererOrgConfig,
  OrgConfig,
} from "../types/FabloConfigExtended";
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
    const { networkSettings, ordererOrgHead, ordererOrgs, orgs, chaincodes } = config;

    const dateString = new Date()
      .toISOString()
      .substring(0, 16)
      .replace(/[^0-9]+/g, "");
    const composeNetworkName = `fablo_network_${dateString}`;

    this.log(`Used network config: ${fabloConfigPath}`);
    this.log(`Fabric version is: ${networkSettings.fabricVersion}`);
    this.log(`Generating docker-compose network '${composeNetworkName}'...`);

    // ======= fabric-config ============================================================
    this._copyOrdererOrgCryptoConfig(ordererOrgs);
    this._copyOrgCryptoConfig(orgs);
    this._copyConfigTx(config);
    this._copyGitIgnore();
    this._createPrivateDataCollectionConfigs(chaincodes);

    // ======= fabric-docker ===========================================================
    this._copyDockerComposeEnv(networkSettings, orgs, composeNetworkName);
    this._copyDockerCompose(networkSettings, ordererOrgHead, ordererOrgs, orgs, chaincodes);

    // ======= scripts ==================================================================
    this._copyCommandsGeneratedScript(config);
    this._copyUtilityScripts(config.networkSettings.capabilities);

    this.on("end", () => {
      this.log("Done & done !!! Try the network out: ");
      this.log("-> fablo.sh up - to start network");
      this.log("-> fablo.sh help - to view all commands");
    });
  }

  _copyConfigTx(config: FabloConfigExtended): void {
    this.fs.copyTpl(
      this.templatePath("fabric-config/configtx.yaml"),
      this.destinationPath("fabric-config/configtx.yaml"),
      config,
    );
  }

  _copyGitIgnore(): void {
    this.fs.copyTpl(this.templatePath("fabric-config/.gitignore"), this.destinationPath("fabric-config/.gitignore"));
  }

  _copyOrdererOrgCryptoConfig(ordererOrgs: OrdererOrgConfig[]): void {
    this.fs.copyTpl(
      this.templatePath("fabric-config/crypto-config-orderers.yaml"),
      this.destinationPath("fabric-config/crypto-config-orderers.yaml"),
      { ordererOrgs },
    );
  }

  _copyOrgCryptoConfig(orgsTransformed: OrgConfig[]): void {
    orgsTransformed.forEach((orgTransformed) => {
      this.fs.copyTpl(
        this.templatePath("fabric-config/crypto-config-org.yaml"),
        this.destinationPath(`fabric-config/${orgTransformed.cryptoConfigFileName}.yaml`),
        { org: orgTransformed },
      );
    });
  }

  _copyDockerComposeEnv(
    networkSettings: NetworkSettings,
    orgsTransformed: OrgConfig[],
    composeNetworkName: string,
  ): void {
    const settings = {
      composeNetworkName,
      fabricCaVersion: networkSettings.fabricCaVersion,
      networkSettings,
      orgs: orgsTransformed,
      paths: networkSettings.paths,
      fabloVersion: config.fabloVersion,
      fabloBuild: getBuildInfo(),
      fabloRestVersion: "0.1.0",
    };
    this.fs.copyTpl(this.templatePath("fabric-docker/.env"), this.destinationPath("fabric-docker/.env"), settings);
  }

  _copyDockerCompose(
    networkSettings: NetworkSettings,
    ordererOrgHead: OrdererOrgConfig,
    ordererOrgs: OrdererOrgConfig[],
    orgs: OrgConfig[],
    chaincodes: ChaincodeConfig[],
  ): void {
    const settings = { networkSettings, ordererOrgHead, ordererOrgs, orgs, chaincodes };
    this.fs.copyTpl(
      this.templatePath("fabric-docker/docker-compose.yaml"),
      this.destinationPath("fabric-docker/docker-compose.yaml"),
      settings,
    );
  }

  _copyCommandsGeneratedScript(config: FabloConfigExtended): void {
    this.fs.copyTpl(
      this.templatePath("fabric-docker/channel-query-scripts.sh"),
      this.destinationPath("fabric-docker/channel-query-scripts.sh"),
      config,
    );
    this.fs.copyTpl(
      this.templatePath("fabric-docker/commands-generated.sh"),
      this.destinationPath("fabric-docker/commands-generated.sh"),
      config,
    );
  }

  _createPrivateDataCollectionConfigs(chaincodes: ChaincodeConfig[]): void {
    chaincodes.forEach(({ privateData, privateDataConfigFile }) => {
      if (privateData !== [] && !!privateDataConfigFile) {
        this.fs.write(
          this.destinationPath(`fabric-config/${privateDataConfigFile}`),
          JSON.stringify(privateData, undefined, 2),
        );
      }
    });
  }

  _copyUtilityScripts(capabilities: Capabilities): void {
    this.fs.copyTpl(this.templatePath("fabric-docker.sh"), this.destinationPath("fabric-docker.sh"));

    this.fs.copyTpl(
      this.templatePath("fabric-docker/scripts/cli/channel_fns.sh"),
      this.destinationPath("fabric-docker/scripts/cli/channel_fns.sh"),
    );

    this.fs.copyTpl(
      this.templatePath("fabric-docker/scripts/cli/channel_fns.sh"),
      this.destinationPath("fabric-docker/scripts/cli/channel_fns.sh"),
    );

    this.fs.copyTpl(
      this.templatePath("fabric-docker/scripts/base-functions.sh"),
      this.destinationPath("fabric-docker/scripts/base-functions.sh"),
    );

    this.fs.copyTpl(
      this.templatePath("fabric-docker/scripts/channel-query-functions.sh"),
      this.destinationPath("fabric-docker/scripts/channel-query-functions.sh"),
    );

    this.fs.copyTpl(
      this.templatePath("fabric-docker/scripts/base-help.sh"),
      this.destinationPath("fabric-docker/scripts/base-help.sh"),
    );

    this.fs.copyTpl(
      this.templatePath(`fabric-docker/scripts/chaincode-functions-${capabilities.isV2 ? "v2" : "v1.4"}.sh`),
      this.destinationPath("fabric-docker/scripts/chaincode-functions.sh"),
    );
  }
}
