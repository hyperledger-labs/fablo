import * as Generator from "yeoman-generator";
import * as config from "../config";
import { getBuildInfo } from "../version/buildUtil";
import { extendConfig } from "../extend-config";
import parseFabricaConfig from "../utils/parseFabricaConfig";
import {
  ChaincodeConfig,
  FabricaConfigExtended,
  NetworkSettings,
  OrgConfig,
  RootOrgConfig,
} from "../types/FabricaConfigExtended";

const ValidateGeneratorPath = require.resolve("../validate");

export default class SetupDockerGenerator extends Generator {
  constructor(args: string[], opts: Generator.GeneratorOptions) {
    super(args, opts);
    this.argument("fabricaConfig", {
      type: String,
      required: true,
      description: "fabrica config file path",
    });

    this.composeWith(ValidateGeneratorPath, { arguments: [this.options.fabricaConfig] });
  }

  async writing(): Promise<void> {
    const fabricaConfigPath = `${this.env.cwd}/${this.options.fabricaConfig}`;
    const json = parseFabricaConfig(this.fs.read(fabricaConfigPath));
    const config = extendConfig(json);
    const { networkSettings, rootOrg, orgs, chaincodes } = config;

    const dateString = new Date()
      .toISOString()
      .substring(0, 16)
      .replace(/[^0-9]+/g, "");
    const composeNetworkName = `fabrica_network_${dateString}`;

    this.log(`Used network config: ${fabricaConfigPath}`);
    this.log(`Fabric version is: ${networkSettings.fabricVersion}`);
    this.log(`Generating docker-compose network '${composeNetworkName}'...`);

    // ======= fabric-config ============================================================
    this._copyRootOrgCryptoConfig(rootOrg);
    this._copyOrgCryptoConfig(orgs);
    this._copyConfigTx(config);
    this._copyGitIgnore();
    this._createPrivateDataCollectionConfigs(chaincodes);

    // ======= fabric-docker ===========================================================
    this._copyDockerComposeEnv(networkSettings, orgs, composeNetworkName);
    this._copyDockerCompose(networkSettings, rootOrg, orgs, chaincodes);

    // ======= scripts ==================================================================
    this._copyCommandsGeneratedScript(config);
    this._copyUtilityScripts();

    this.on("end", () => {
      this.log("Done & done !!! Try the network out: ");
      this.log("-> fabrica.sh up - to start network");
      this.log("-> fabrica.sh help - to view all commands");
    });
  }

  _copyConfigTx(config: FabricaConfigExtended): void {
    this.fs.copyTpl(
      this.templatePath("fabric-config/configtx.yaml"),
      this.destinationPath("fabric-config/configtx.yaml"),
      config,
    );
  }

  _copyGitIgnore(): void {
    this.fs.copyTpl(this.templatePath("fabric-config/.gitignore"), this.destinationPath("fabric-config/.gitignore"));
  }

  _copyRootOrgCryptoConfig(rootOrg: RootOrgConfig): void {
    this.fs.copyTpl(
      this.templatePath("fabric-config/crypto-config-root.yaml"),
      this.destinationPath("fabric-config/crypto-config-root.yaml"),
      { rootOrg },
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
      fabricaVersion: config.fabricaVersion,
      fabricaBuild: getBuildInfo(),
    };
    this.fs.copyTpl(this.templatePath("fabric-docker/.env"), this.destinationPath("fabric-docker/.env"), settings);
  }

  _copyDockerCompose(
    networkSettings: NetworkSettings,
    rootOrg: RootOrgConfig,
    orgs: OrgConfig[],
    chaincodes: ChaincodeConfig[],
  ): void {
    const settings = { networkSettings, rootOrg, orgs, chaincodes };
    this.fs.copyTpl(
      this.templatePath("fabric-docker/docker-compose.yaml"),
      this.destinationPath("fabric-docker/docker-compose.yaml"),
      settings,
    );
  }

  _copyCommandsGeneratedScript(config: FabricaConfigExtended): void {
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

  _copyUtilityScripts(): void {
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
      this.templatePath("fabric-docker/scripts/chaincode-functions.sh"),
      this.destinationPath("fabric-docker/scripts/chaincode-functions.sh"),
    );
  }
}
