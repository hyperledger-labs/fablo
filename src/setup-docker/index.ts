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
  Global,
  OrgConfig,
} from "../types/FabloConfigExtended";
import { extendConfig } from "../extend-config/";
import {
  createConnectionProfile,
  createExplorerConnectionProfile,
  OrgWithChannels,
  pairOrgWithChannels,
} from "../types/ConnectionProfile";
import { createExplorerConfig } from "../types/ExplorerConfig";

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

    console.log(`Used network config: ${fabloConfigPath}`);
    console.log(`Fabric version is: ${global.fabricVersion}`);
    console.log(`Generating docker-compose network '${composeNetworkName}'...`);

    // ======= fabric-config ============================================================
    this._copyOrgCryptoConfig(orgs);
    this._createConnectionProfiles(global, orgs);
    this._createFabricCaServerConfigs(orgs);
    this._createExplorerMaterial(global, orgs, channels);
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
      console.log("Done & done !!! Try the network out: ");
      console.log("-> fablo up - to start network");
      console.log("-> fablo help - to view all commands");
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

  _createConnectionProfiles(global: Global, orgsTransformed: OrgConfig[]): void {
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

  _createFabricCaServerConfigs(orgsTransformed: OrgConfig[]): void {
    orgsTransformed.forEach((orgTransformed: OrgConfig) => {
      this.fs.copyTpl(
        this.templatePath("fabric-config/fabric-ca-server-config.yaml"),
        this.destinationPath(
          `fabric-config/fabric-ca-server-config/${orgTransformed.domain}/fabric-ca-server-config.yaml`,
        ),
        { org: orgTransformed },
      );
    });
  }

  _createExplorerMaterial(global: Global, orgsTransformed: OrgConfig[], channels: ChannelConfig[]): void {
    const orgs = orgsTransformed.filter((o) => o.anchorPeers.length > 0);
    const orgWithChannels = pairOrgWithChannels(orgs, channels);

    orgWithChannels
      .filter((p: OrgWithChannels) => global.tools.explorer !== undefined || p.org.tools.explorer !== undefined)
      .forEach((p: OrgWithChannels) => {
        const connectionProfile = createExplorerConnectionProfile(global, p, orgsTransformed);
        const orgName = p.org.name.toLowerCase();
        this.fs.writeJSON(
          this.destinationPath(`fabric-config/explorer/connection-profile-${orgName}.json`),
          connectionProfile,
        );
        this.fs.writeJSON(
          this.destinationPath(`fabric-config/explorer/config-${orgName}.json`),
          createExplorerConfig([p.org]),
        );
      });

    this.fs.writeJSON(
      this.destinationPath("fabric-config/explorer/config-global.json"),
      createExplorerConfig(orgWithChannels.map((p) => p.org)),
    );
  }

  _copyDockerComposeEnv(global: Global, orgsTransformed: OrgConfig[], composeNetworkName: string): void {
    const settings = {
      composeNetworkName,
      fabricCaVersion: global.fabricCaVersion,
      global,
      orgs: orgsTransformed,
      paths: global.paths,
      fabloVersion: config.fabloVersion,
      fabloBuild: getBuildInfo(),
      fabloRestVersion: "0.1.2",
      hyperledgerExplorerVersion: "2.0.0",
      fabricCouchDbVersion: "0.4.18",
      couchDbVersion: "3.1",
      fabricCaPostgresVersion: "14",
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
    this.fs.copyTpl(
      this.templatePath("fabric-docker/chaincode-scripts.sh"),
      this.destinationPath("fabric-docker/chaincode-scripts.sh"),
      config,
    );
    this.fs.copyTpl(
      this.templatePath("fabric-docker/snapshot-scripts.sh"),
      this.destinationPath("fabric-docker/snapshot-scripts.sh"),
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
      if (privateData && privateData.length && !!privateDataConfigFile) {
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
      this.templatePath(`fabric-docker/scripts/cli/channel_fns-${capabilities.isV3 ? "v3" : "v2"}.sh`),
      this.destinationPath("fabric-docker/scripts/cli/channel_fns.sh"),
    );

    this.fs.copyTpl(
      this.templatePath(`fabric-docker/scripts/base-functions-${capabilities.isV3 ? "v3" : "v2"}.sh`),
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
      this.templatePath(`fabric-docker/scripts/chaincode-functions-${capabilities.isV2 ? "v2" : "v2"}.sh`),
      this.destinationPath("fabric-docker/scripts/chaincode-functions.sh"),
    );
  }

  _copyHooks(hooks: HooksConfig): void {
    this.fs.copyTpl(this.templatePath("hooks/post-generate.sh"), this.destinationPath("hooks/post-generate.sh"), {
      hooks,
    });
  }
}
