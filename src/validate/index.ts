import * as Generator from "yeoman-generator";
import { Validator as SchemaValidator } from "jsonschema";
import * as chalk from "chalk";
import * as config from "../config";
import parseFabloConfig from "../utils/parseFabloConfig";
import {
  ChaincodeJson,
  ChannelJson,
  FabloConfigJson,
  GlobalJson,
  OrdererJson,
  OrgJson,
} from "../types/FabloConfigJson";
import * as _ from "lodash";
import { getNetworkCapabilities } from "../extend-config/";
import { Capabilities } from "../types/FabloConfigExtended";
import { version } from "../repositoryUtils";

const ListCompatibleUpdatesGeneratorType = require.resolve("../list-compatible-updates");
const findDuplicatedItems = (arr: unknown[]) => arr.filter((item, index) => arr.indexOf(item) != index);

const validationErrorType = {
  CRITICAL: "validation-critical",
  ERROR: "validation-error",
  WARN: "validation-warning",
};

const validationCategories = {
  CRITICAL: "Critical",
  GENERAL: "General",
  ORGS: "Orgs",
  ORDERER: "Orderer",
  PEER: "Peer",
  CHAINCODE: "Chaincode",
  CHANNEL: "Channel",
  VALIDATION: "Schema validation",
};

interface Message {
  category: string;
  message: string;
}

class Listener {
  readonly messages: Message[] = [];

  onEvent(event: Message) {
    this.messages.push(event);
  }

  getAllMessages() {
    return this.messages;
  }

  count() {
    return this.messages.length;
  }
}

const getFullPathOf = (configFile: string, currentPath: string): string => `${currentPath}/${configFile}`;

class ValidateGenerator extends Generator {
  private readonly errors = new Listener();
  private readonly warnings = new Listener();

  constructor(args: string[], opts: Generator.GeneratorOptions) {
    super(args, opts);

    this.argument("fabloConfig", {
      type: String,
      optional: true,
      description: "Fablo config file path",
      default: "../../network/fablo-config.json",
    });

    this.addListener(validationErrorType.CRITICAL, (event) => {
      this.log(chalk.bold.bgRed("Critical error occured:"));
      this.log(chalk.bold(`- ${event.message}`));
      this._printIfNotEmpty(this.errors.getAllMessages(), chalk.red.bold("Errors found:"));
      process.exit(1);
    });

    this.addListener(validationErrorType.ERROR, (e) => this.errors.onEvent(e));
    this.addListener(validationErrorType.WARN, (e) => this.warnings.onEvent(e));

    this.composeWith(ListCompatibleUpdatesGeneratorType);
  }

  async validate() {
    this._validateIfConfigFileExists(this.options.fabloConfig);

    const networkConfig = parseFabloConfig(this.fs.read(this.options.fabloConfigPath));
    this._validateJsonSchema(networkConfig);
    this._validateSupportedFabloVersion(networkConfig.$schema);
    this._validateFabricVersion(networkConfig.global.fabricVersion);
    this._validateOrgs(networkConfig.orgs);
    this._validateEngineSpecificSettings(networkConfig);

    // === Validate Orderers =============
    this._validateIfOrdererDefinitionExists(networkConfig.orgs);
    networkConfig.orgs.forEach((org) => this._validateOrdererCountForSoloType(org.orderers));
    networkConfig.orgs.forEach((org) => this._validateOrdererForRaftType(org.orderers, networkConfig.global));
    networkConfig.orgs.forEach((org) => this._validateOrdererCountForOrg(org));
    networkConfig.orgs.forEach((org) => this._validateOrdererGroupNameUniqueForOrg(org));
    // ===================================

    // === Validate Channel =============
    this._validateChannelNames(networkConfig.channels);
    this._validateChannelOrgPeers(networkConfig.channels, networkConfig.orgs);
    // ===================================

    this._validateChaincodeNames(networkConfig.chaincodes);

    this._validateOrgsAnchorPeerInstancesCount(networkConfig.orgs);
    this._validateChannelOrdererGroup(networkConfig.orgs, networkConfig.channels);
    this._validateIfSameOrdererTypeAcrossOrdererGroup(networkConfig.orgs);

    const capabilities = getNetworkCapabilities(networkConfig.global.fabricVersion);
    this._validateChaincodes(capabilities, networkConfig.chaincodes);
    this._validateExplorer(networkConfig.global, networkConfig.orgs);
    this._validateExplorerWithFabricVersion(networkConfig.global, networkConfig.orgs);
    this._validateDevMode(networkConfig.global);
  }

  async shortSummary() {
    this.log(`Validation errors count: ${this.errors.count()}`);
    this.log(`Validation warnings count: ${this.warnings.count()}`);
    this.log(chalk.bold("==========================================================="));
  }

  async detailedSummary() {
    const allValidationMessagesCount = this.errors.count() + this.warnings.count();

    if (allValidationMessagesCount > 0) {
      this.log(chalk.bold("=================== Validation summary ===================="));
      this._printIfNotEmpty(this.errors.getAllMessages(), chalk.red.bold("Errors found:"));
      this._printIfNotEmpty(this.warnings.getAllMessages(), chalk.yellow("Warnings found:"));
      this.log(chalk.bold("==========================================================="));
    }

    if (this.errors.count() > 0) {
      process.exit(1);
    }
  }

  _validateIfConfigFileExists(configFilePath: string) {
    const configFilePathAbsolute = getFullPathOf(configFilePath, this.env.cwd);
    const fileExists = this.fs.exists(configFilePathAbsolute);
    if (!fileExists) {
      const objectToEmit: Message = {
        category: validationCategories.CRITICAL,
        message: `No file under path: ${configFilePathAbsolute}`,
      };
      this.emit(validationErrorType.CRITICAL, objectToEmit);
    } else {
      this.options.fabloConfigPath = configFilePathAbsolute;
    }
  }

  _validateJsonSchema(configToValidate: FabloConfigJson) {
    const validator = new SchemaValidator();
    const results = validator.validate(configToValidate, config.schema);
    results.errors.forEach((result) => {
      const msg = `${result.property} : ${result.message}`;
      const objectToEmit = {
        category: validationCategories.VALIDATION,
        message: msg,
      };
      this.emit(validationErrorType.ERROR, objectToEmit);
    });
    if (results.errors.length > 0) {
      const objectToEmit = {
        category: validationCategories.CRITICAL,
        message: "Json schema validation failed!",
      };
      this.emit(validationErrorType.CRITICAL, objectToEmit);
    }
  }

  _printIfNotEmpty(messages: Message[], caption: string) {
    if (messages.length > 0) {
      this.log(caption);

      const grouped: Record<string, Message[]> = _.groupBy(messages, (msg) => msg.category);

      Object.keys(grouped).forEach((key) => {
        this.log(chalk.bold(`  ${key}:`));
        grouped[key].forEach((msg) => this.log(`   - ${msg.message}`));
      });
    }
  }

  _validateSupportedFabloVersion(schemaUrl: string) {
    const version = config.getVersionFromSchemaUrl(schemaUrl);
    if (!config.isFabloVersionSupported(version)) {
      const msg = `Config file points to '${version}' Fablo version which is not supported. Supported versions are: ${config.supportedVersionPrefix}x`;
      const objectToEmit = {
        category: validationCategories.CRITICAL,
        message: msg,
      };
      this.emit(validationErrorType.CRITICAL, objectToEmit);
    }
  }

  _validateFabricVersion(fabricVersion: string) {
    if (!config.supportedFabricVersions.includes(fabricVersion)) {
      const objectToEmit = {
        category: validationCategories.GENERAL,
        message: `Hyperledger Fabric '${fabricVersion}' version is not supported. Supported versions are: ${config.supportedFabricVersions}`,
      };
      this.emit(validationErrorType.ERROR, objectToEmit);
    }
  }

  _validateOrdererCountForOrg(org: OrgJson) {
    const numerOfOrderersInOrg = org.orderers?.flatMap((o) => o.instances).reduce((a, b) => a + b, 0);
    if (numerOfOrderersInOrg !== undefined && numerOfOrderersInOrg > 9) {
      const objectToEmit = {
        category: validationCategories.ORDERER,
        message: `You've reached Fablo limits! :/ Single org may have only 9 Orderers in total, but '${org.organization.name}' has ${numerOfOrderersInOrg} Orderers in total.`,
      };
      this.emit(validationErrorType.ERROR, objectToEmit);
    }
  }

  _validateOrdererGroupNameUniqueForOrg(org: OrgJson) {
    const groupNames = org.orderers?.flatMap((o) => o.groupName);
    const duplicatedGroupNames = groupNames != undefined ? findDuplicatedItems(groupNames) : [];
    if (duplicatedGroupNames.length > 0) {
      const objectToEmit = {
        category: validationCategories.ORDERER,
        message: `groupName must be unique within every organization, but '${duplicatedGroupNames}' is not`,
      };
      this.emit(validationErrorType.ERROR, objectToEmit);
    }
  }

  _validateOrdererCountForSoloType(orderers: OrdererJson[] | undefined) {
    if (orderers !== undefined) {
      orderers.forEach((orderer) => {
        if (orderer.type === "solo" && orderer.instances > 1) {
          const objectToEmit = {
            category: validationCategories.ORDERER,
            message: `Orderer consesus type is set to 'solo', but number of instances is ${orderer.instances}. Only 1 instance will be created.`,
          };
          this.emit(validationErrorType.WARN, objectToEmit);
        }
      });
    }
  }

  _validateOrdererForRaftType(orderers: OrdererJson[] | undefined, global: GlobalJson) {
    if (orderers !== undefined) {
      orderers
        .filter((o) => o.type === "raft")
        .forEach((orderer) => {
          if (orderer.instances === 1) {
            const objectToEmit = {
              category: validationCategories.ORDERER,
              message: `Orderer consesus type is set to '${orderer.type}', but number of instances is 1. Network won't be fault tolerant! Consider higher value.`,
            };
            this.emit(validationErrorType.WARN, objectToEmit);
          }

          if (!config.versionsSupportingRaft.includes(global.fabricVersion)) {
            const objectToEmit = {
              category: validationCategories.ORDERER,
              message: `Fabric's ${global.fabricVersion} does not support Raft consensus type. Supporting versions are: ${config.versionsSupportingRaft}`,
            };
            this.emit(validationErrorType.ERROR, objectToEmit);
          }
          if (!global.tls) {
            const objectToEmit = {
              category: validationCategories.ORDERER,
              message: "Raft consensus type must use network in TLS mode. Try setting 'global.tls' to true",
            };
            this.emit(validationErrorType.ERROR, objectToEmit);
          }
        });
    }
  }

  _validateOrgsAnchorPeerInstancesCount(orgs: OrgJson[]) {
    orgs.forEach((org) => {
      const numberOfPeers = org.peer?.instances;
      const numberOfAnchorPeers = org.peer?.anchorPeerInstances;

      if (numberOfPeers !== undefined && numberOfAnchorPeers !== undefined) {
        if (!!numberOfAnchorPeers && numberOfPeers < numberOfAnchorPeers) {
          const objectToEmit = {
            category: validationCategories.PEER,
            message: `Too many anchor peers for organization "${org.organization.name}". Peer count: ${numberOfPeers}, anchor peer count: ${numberOfAnchorPeers}`,
          };
          this.emit(validationErrorType.ERROR, objectToEmit);
        }
      }
    });
  }

  _validateChaincodes(capabilities: Capabilities, chaincodes: ChaincodeJson[]) {
    chaincodes.forEach((chaincode) => {
      if (!!chaincode.init && capabilities.isV2) {
        const objectToEmit = {
          category: validationCategories.CHAINCODE,
          message: `Chaincode 'init' parameters are only supported in Fabric prior to 2.0 (${chaincode.name})`,
        };
        this.emit(validationErrorType.WARN, objectToEmit);
      }
      if (!!chaincode.initRequired && !capabilities.isV2) {
        const objectToEmit = {
          category: validationCategories.CHAINCODE,
          message: `Chaincode 'initRequired' parameter is supported only in Fabric prior to 2.0 and will be ignored (${chaincode.name})`,
        };
        this.emit(validationErrorType.WARN, objectToEmit);
      }
    });
  }

  _validateChannelOrdererGroup(orgs: OrgJson[], channels: ChannelJson[]) {
    const groupNamesArr = orgs
      .flatMap((org) => org.orderers?.map((o) => o.groupName))
      .filter((name): name is string => name !== undefined);
    const groupNames = new Set(groupNamesArr);

    channels.forEach((channel) => {
      if (channel.ordererGroup !== undefined && !groupNames.has(channel.ordererGroup)) {
        const objectToEmit = {
          category: validationCategories.CHANNEL,
          message: `Channel '${channel.name}' has non valid ordererGroup defined. ordererGroup is '${channel.ordererGroup}', proper options: [${groupNames}]`,
        };
        this.emit(validationErrorType.ERROR, objectToEmit);
      }
    });
  }

  _validateChannelOrgPeers(channels: ChannelJson[], orgs: OrgJson[]) {
    const isOrgWithoutPeers = (org: OrgJson): boolean => org.peer === undefined;
    const getOrgNames = (channel: ChannelJson): string[] => channel.orgs.map((o) => o.name);
    const isOrgInChannel = (org: OrgJson, orgsInChannel: string[]): boolean =>
      orgsInChannel.includes(org.organization.name);

    channels.forEach((channel) => {
      const orgsInChannel = getOrgNames(channel);

      orgs
        .filter((org) => isOrgInChannel(org, orgsInChannel))
        .filter(isOrgWithoutPeers)
        .forEach((orgWithoutPeers) => {
          const objectToEmit = {
            category: validationCategories.CHANNEL,
            message: `You can't join org without peers to a channel. Check channel '${channel.name}' and org '${orgWithoutPeers.organization.name}'`,
          };
          this.emit(validationErrorType.ERROR, objectToEmit);
        });
    });
  }

  _validateChannelNames(channels: ChannelJson[]) {
    const channelNames = channels.map((ch) => ch.name);
    const duplicatedChannelNames = findDuplicatedItems(channelNames);

    duplicatedChannelNames.forEach((duplicatedName) => {
      const objectToEmit = {
        category: validationCategories.CHANNEL,
        message: `Channel name '${duplicatedName}' is not unique.`,
      };
      this.emit(validationErrorType.ERROR, objectToEmit);
    });
  }

  _validateChaincodeNames(chaincodes: ChaincodeJson[]) {
    const chaincodeNames = chaincodes.map((ch) => ch.name);
    const duplicatedChaincodeNames = findDuplicatedItems(chaincodeNames);

    duplicatedChaincodeNames.forEach((duplicatedName) => {
      const objectToEmit = {
        category: validationCategories.CHAINCODE,
        message: `Chaincode name '${duplicatedName}' is not unique.`,
      };
      this.emit(validationErrorType.ERROR, objectToEmit);
    });
  }

  _validateIfSameOrdererTypeAcrossOrdererGroup(orgs: OrgJson[]) {
    const isOrdererDefined = (org: OrgJson): boolean => org.orderers != undefined;

    const ordererBlocks = orgs.filter(isOrdererDefined).flatMap((orgs) => orgs.orderers as OrdererJson[]);

    const ordererBlocksGrouped: Record<string, OrdererJson[]> = _.groupBy(ordererBlocks, (group) => group.groupName);

    Object.values(ordererBlocksGrouped).forEach((groupItems) => {
      const groupName = groupItems[0].groupName;
      const ordererTypes = groupItems.map((item) => item.type);

      if (new Set(ordererTypes).size != 1) {
        const objectToEmit = {
          category: validationCategories.ORDERER,
          message: `Orderer group '${groupName}' should have same orderer type across whole group. Found types: '${ordererTypes}'`,
        };
        this.emit(validationErrorType.ERROR, objectToEmit);
      }
    });
  }

  _validateIfOrdererDefinitionExists(orgs: OrgJson[]) {
    const numerOfOrdererBlocks = orgs.filter((org) => org.orderers !== undefined).length;
    if (numerOfOrdererBlocks < 1) {
      const objectToEmit = {
        category: validationCategories.ORDERER,
        message: `Orderer block is not defined in any org. At least 1 orderer block is mandatory!`,
      };
      this.emit(validationErrorType.ERROR, objectToEmit);
    }
  }

  _validateOrgs(orgs: OrgJson[]) {
    const isOrgWithoutPeers = (org: OrgJson): boolean => org.peer === undefined;
    const isOrgWithoutOrderers = (org: OrgJson): boolean => org.orderers === undefined;

    orgs
      .filter((o) => isOrgWithoutPeers(o) && isOrgWithoutOrderers(o))
      .forEach((org) => {
        const objectToEmit = {
          category: validationCategories.ORGS,
          message: `Org '${org.organization.name}' doesn't have Peers or Orderers.`,
        };
        this.emit(validationErrorType.WARN, objectToEmit);
      });
  }

  _validateEngineSpecificSettings(networkConfig: FabloConfigJson): void {
    if (networkConfig.global.engine === "kubernetes") {
      if (!version(networkConfig.global.fabricVersion).isGreaterOrEqual("2.0.0")) {
        this.emit(validationErrorType.ERROR, {
          category: validationCategories.GENERAL,
          message: `Kubernetes is not supported by Fablo for Fabric below version 2.0.0`,
        });
      }
    }

    // TODO engine-specific validation rules
  }

  _validateExplorer(global: GlobalJson, orgs: OrgJson[]): void {
    if (global.tools?.explorer === true) {
      orgs
        .filter((o) => o.tools?.explorer === true)
        .forEach((o) => {
          const objectToEmit = {
            category: validationCategories.ORGS,
            message: `Explorer for organization '${o.organization.name}' is enabled, however it will be ignored due to global explorer enabled.`,
          };
          this.emit(validationErrorType.WARN, objectToEmit);
        });
    }
  }

  _validateExplorerWithFabricVersion(global: GlobalJson, orgs: OrgJson[]): void {
    const fabricVersion = global.fabricVersion;
    if (!version(fabricVersion).isGreaterOrEqual("1.4.0") || version(fabricVersion).isGreaterOrEqual("2.4.0")) {
      const warnMessage = `You are using fabric version '${global.fabricVersion}' which may not be supported by the Hyperledger Explorer`;
      if (global.tools?.explorer === true) {
        this.emit(validationErrorType.WARN, { category: validationCategories.GENERAL, message: warnMessage });
      } else {
        orgs
          .filter((o) => o.tools?.explorer === true)
          .forEach(() => {
            this.emit(validationErrorType.WARN, {
              category: validationCategories.ORGS,
              message: warnMessage,
            });
          });
      }
    }
  }

  _validateDevMode(global: GlobalJson): void {
    if (global.peerDevMode) {
      if (global.tls) {
        const message = `TLS needs to be disabled when running peers in dev mode`;
        this.emit(validationErrorType.ERROR, { category: validationCategories.GENERAL, message });
      }
      if (!version(global.fabricVersion).isGreaterOrEqual("2.0.0")) {
        const message = `Fablo supports dev mode only for Fabric in version 2.0.0 and higher`;
        this.emit(validationErrorType.ERROR, { category: validationCategories.GENERAL, message });
      }
    }
  }
}

module.exports = ValidateGenerator;
