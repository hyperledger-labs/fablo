import * as Generator from "yeoman-generator";
import * as config from "../config";
import * as yaml from "js-yaml";
import { getBuildInfo } from "../version/buildUtil";
import parseFabloConfig from "../utils/parseFabloConfig";
import {
  Capabilities,
  ChaincodeConfig,
  ChannelConfig,
  FabloConfigExtended,
  HooksConfig,
  NetworkSettings,
  OrgConfig,
} from "../types/FabloConfigExtended";
import { extendConfig } from "../extend-config/";
import { createConnectionProfile, createHyperledgerExplorerConnectionProfile } from "../types/ConnectionProfile";

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
    const { global, orgs, chaincodes, channels } = config;

    const dateString = new Date()
      .toISOString()
      .substring(0, 16)
      .replace(/[^0-9]+/g, "");
    const composeNetworkName = `fablo_network_${dateString}`;

    this.log(`Used network config: ${fabloConfigPath}`);
    this.log(`Fabric version is: ${global.fabricVersion}`);
    this.log(`Generating docker-compose network '${composeNetworkName}'...`);

    // ======= fabric-config ============================================================
    this._copyOrgCryptoConfig(orgs);
    this._createConnectionProfiles(global, orgs);
    this._createHyperledgerExplorerMaterial(global, orgs, channels);
    this._copyConfigTx(config);
    this._copyGitIgnore();
    this._createPrivateDataCollectionConfigs(chaincodes);

    // ======= fabric-docker ===========================================================
    this._copyDockerComposeEnv(global, orgs, composeNetworkName);
    this._copyDockerCompose(config);

    // ======= scripts ==================================================================
    this._copyCommandsGeneratedScript(config);
    this._copyUtilityScripts(config.global.capabilities);

    // ======= hooks ====================================================================
    this._copyHooks(config.hooks);

    this.on("end", () => {
      this.log("Done & done !!! Try the network out: ");
      this.log("-> fablo up - to start network");
      this.log("-> fablo help - to view all commands");
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

  _copyOrgCryptoConfig(orgsTransformed: OrgConfig[]): void {
    orgsTransformed.forEach((orgTransformed) => {
      this.fs.copyTpl(
        this.templatePath("fabric-config/crypto-config-org.yaml"),
        this.destinationPath(`fabric-config/${orgTransformed.cryptoConfigFileName}.yaml`),
        { org: orgTransformed },
      );
    });
  }

  _createConnectionProfiles(global: NetworkSettings, orgsTransformed: OrgConfig[]): void {
    orgsTransformed.forEach((org: OrgConfig) => {
      const connectionProfile = createConnectionProfile(global, org, orgsTransformed);
      this.fs.writeJSON(
        this.destinationPath(`fabric-config/connection-profiles/connection-profile-${org.name.toLowerCase()}.json`),
        connectionProfile,
      );
      this.fs.write(
        this.destinationPath(`fabric-config/connection-profiles/connection-profile-${org.name.toLowerCase()}.yaml`),
        yaml.dump(connectionProfile),
      );
    });
  }

  _createHyperledgerExplorerMaterial(
    global: NetworkSettings,
    orgsTransformed: OrgConfig[],
    channels: ChannelConfig[],
  ): void {
    orgsTransformed
      .filter((o) => o.tools.explorer !== undefined)
      .forEach((org: OrgConfig) => {
        const connectionProfile = createHyperledgerExplorerConnectionProfile(
          global,
          org,
          orgsTransformed,
          channels,
        );
        const orgName = org.name.toLowerCase();
        this.fs.writeJSON(
          this.destinationPath(`fabric-config/explorer/connection-profile-${orgName}.json`),
          connectionProfile,
        );
        this.fs.copyTpl(
          this.templatePath("fabric-config/explorer/config.json"),
          this.destinationPath(`fabric-config/explorer/config-${orgName}.json`),
          { orgName },
        );
      });
  }

  _copyDockerComposeEnv(
    global: NetworkSettings,
    orgsTransformed: OrgConfig[],
    composeNetworkName: string,
  ): void {
    const settings = {
      composeNetworkName,
      fabricCaVersion: global.fabricCaVersion,
      global,
      orgs: orgsTransformed,
      paths: global.paths,
      fabloVersion: config.fabloVersion,
      fabloBuild: getBuildInfo(),
      fabloRestVersion: "0.1.0",
      hyperledgerExplorerVersion: "1.1.8",
    };
    this.fs.copyTpl(this.templatePath("fabric-docker/.env"), this.destinationPath("fabric-docker/.env"), settings);
  }

  _copyDockerCompose(config: FabloConfigExtended): void {
    this.fs.copyTpl(
      this.templatePath("fabric-docker/docker-compose.yaml"),
      this.destinationPath("fabric-docker/docker-compose.yaml"),
      config,
    );
  }

  _copyCommandsGeneratedScript(config: FabloConfigExtended): void {
    this.fs.copyTpl(
      this.templatePath("fabric-docker/channel-query-scripts.sh"),
      this.destinationPath("fabric-docker/channel-query-scripts.sh"),
      config,
    );
    this.fs.copy(
      this.templatePath("fabric-docker/snapshot-scripts.sh"),
      this.destinationPath("fabric-docker/snapshot-scripts.sh"),
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

  _copyHooks(hooks: HooksConfig): void {
    this.fs.copyTpl(this.templatePath("hooks/post-generate.sh"), this.destinationPath("hooks/post-generate.sh"), {
      hooks,
    });
  }
}
