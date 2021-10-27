import * as Generator from "yeoman-generator";
import { Validator as SchemaValidator } from "jsonschema";
import * as chalk from "chalk";
import * as config from "../config";
import parseFabloConfig from "../utils/parseFabloConfig";
import {
  ChaincodeJson,
  ChannelJson,
  FabloConfigJson,
  NetworkSettingsJson,
  OrdererJson,
  OrdererOrgJson,
  OrgJson,
} from "../types/FabloConfigJson";
import * as _ from "lodash";
import { getNetworkCapabilities } from "../extend-config/";
import { Capabilities } from "../types/FabloConfigExtended";

const ListCompatibleUpdatesGeneratorType = require.resolve("../list-compatible-updates");
const findDuplicatedItems = (arr: any[]) => arr.filter((item, index) => arr.indexOf(item) != index);

const validationErrorType = {
  CRITICAL: "validation-critical",
  ERROR: "validation-error",
  WARN: "validation-warning",
};

const validationCategories = {
  CRITICAL: "Critical",
  GENERAL: "General",
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

  async initializing() {
    this.log(config.splashScreen());
  }

  async validate() {
    this._validateIfConfigFileExists(this.options.fabloConfig);

    const networkConfig = parseFabloConfig(this.fs.read(this.options.fabloConfigPath));
    this._validateJsonSchema(networkConfig);
    this._validateSupportedFabloVersion(networkConfig.$schema);
    this._validateFabricVersion(networkConfig.networkSettings.fabricVersion);

    networkConfig.ordererOrgs.forEach((ordererOrg) => this._validateOrdererCountForSoloType(ordererOrg.orderer));
    networkConfig.ordererOrgs.forEach((ordererOrg) =>
      this._validateOrdererForRaftType(ordererOrg.orderer, networkConfig.networkSettings),
    );

    this._validateChannelNames(networkConfig.channels);
    this._validateChaincodeNames(networkConfig.chaincodes);

    this._validateOrgsAnchorPeerInstancesCount(networkConfig.orgs);
    this._validateChannelOrdererGroup(networkConfig.ordererOrgs, networkConfig.orgs, networkConfig.channels);
    this._validateIfSameOrdererTypeAcrossOrdererGroup(networkConfig.ordererOrgs, networkConfig.orgs);

    const capabilities = getNetworkCapabilities(networkConfig.networkSettings.fabricVersion);
    this._validateChaincodes(capabilities, networkConfig.chaincodes);
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

  _validateOrdererCountForSoloType(orderer: OrdererJson) {
    if (orderer.type === "solo" && orderer.instances > 1) {
      const objectToEmit = {
        category: validationCategories.ORDERER,
        message: `Orderer consesus type is set to 'solo', but number of instances is ${orderer.instances}. Only 1 instance will be created.`,
      };
      this.emit(validationErrorType.WARN, objectToEmit);
    }
  }

  _validateOrdererForRaftType(orderer: OrdererJson, networkSettings: NetworkSettingsJson) {
    if (orderer.type === "raft") {
      if (orderer.instances === 1) {
        const objectToEmit = {
          category: validationCategories.ORDERER,
          message: `Orderer consesus type is set to '${orderer.type}', but number of instances is 1. Network won't be fault tolerant! Consider higher value.`,
        };
        this.emit(validationErrorType.WARN, objectToEmit);
      }

      if (!config.versionsSupportingRaft.includes(networkSettings.fabricVersion)) {
        const objectToEmit = {
          category: validationCategories.ORDERER,
          message: `Fabric's ${networkSettings.fabricVersion} does not support Raft consensus type. Supporting versions are: ${config.versionsSupportingRaft}`,
        };
        this.emit(validationErrorType.ERROR, objectToEmit);
      }

      if (!networkSettings.tls) {
        const objectToEmit = {
          category: validationCategories.ORDERER,
          message: "Raft consensus type must use network in TLS mode. Try setting 'networkSettings.tls' to true",
        };
        this.emit(validationErrorType.ERROR, objectToEmit);
      }
    }
  }

  _validateOrgsAnchorPeerInstancesCount(orgs: OrgJson[]) {
    orgs.forEach((org) => {
      const numberOfPeers = org.peer.instances;
      const numberOfAnchorPeers = org.peer.anchorPeerInstances;

      if (!!numberOfAnchorPeers && numberOfPeers < numberOfAnchorPeers) {
        const objectToEmit = {
          category: validationCategories.PEER,
          message: `Too many anchor peers for organization "${org.organization.name}". Peer count: ${numberOfPeers}, anchor peer count: ${numberOfAnchorPeers}`,
        };
        this.emit(validationErrorType.ERROR, objectToEmit);
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

  _validateChannelOrdererGroup(ordererOrgs: OrdererOrgJson[], orgs: OrgJson[], channels: ChannelJson[]) {
    const o1 = ordererOrgs.map((org) => org.orderer.groupName);
    const o2 = orgs.map((org) => org.orderer?.groupName).filter((n) => n != undefined) as string[];

    const groupNames = new Set(o1.concat(o2));

    channels.forEach((channel) => {
      if (typeof channel.ordererGroup != "undefined") {
        if (!groupNames.has(channel.ordererGroup)) {
          const objectToEmit = {
            category: validationCategories.CHANNEL,
            message: `Channel '${channel.name}' has non valid ordererOrg defined. ordererGroup: '${channel.ordererGroup}', proper options: [${groupNames}]`,
          };
          this.emit(validationErrorType.ERROR, objectToEmit);
        }
      }
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

  _validateIfSameOrdererTypeAcrossOrdererGroup(ordererOrgs: OrdererOrgJson[], orgs: OrgJson[]) {
    const isOrdererDefined = (org: OrgJson): boolean => org.orderer != undefined;

    const orderersOrdererOrgs = ordererOrgs.map((ordererOrg) => ordererOrg.orderer);
    const orderersOrgs = orgs.filter(isOrdererDefined).map((orgs) => orgs.orderer as OrdererJson);

    const allOrdererBlocks = orderersOrdererOrgs.concat(orderersOrgs);

    const grouped: Record<string, OrdererJson[]> = _.groupBy(allOrdererBlocks, (group) => group.groupName);

    Object.values(grouped).forEach((groupItems) => {
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
}

module.exports = ValidateGenerator;
