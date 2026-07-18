import { Args, Command, Flags } from "@oclif/core";
import * as chalk from "chalk";
import { GlobalJson, FabloConfigJson, ChaincodeJson, OrgJson } from "../../types/FabloConfigJson";
import { Validator as SchemaValidator } from "jsonschema";
import * as _ from "lodash";
import * as path from "path";
import * as fs from "fs-extra";
import { version } from "../../../package.json";
import { schema } from "../../config";

function getDefaultFabloConfig(): FabloConfigJson {
  return {
    $schema: `https://github.com/hyperledger-labs/fablo/releases/download/${version}/schema.json`,
    global: {
      fabricVersion: "3.1.0",
      tls: true,
      peerDevMode: false,
    },
    orgs: [
      {
        organization: {
          name: "Orderer",
          domain: "orderer.example.com",
          mspName: "OrdererMSP",
        },
        ca: {
          prefix: "ca",
          db: "sqlite",
        },
        orderers: [
          {
            groupName: "group1",
            type: "BFT",
            instances: 2,
            prefix: "orderer",
          },
        ],
      },
      {
        organization: {
          name: "Org1",
          domain: "org1.example.com",
          mspName: "Org1MSP",
        },
        ca: {
          prefix: "ca",
          db: "sqlite",
        },
        orderers: [],
        peer: {
          instances: 2,
          db: "LevelDb",
          prefix: "peer",
        },
      },
    ],
    channels: [
      {
        name: "my-channel1",
        orgs: [
          {
            name: "Org1",
            peers: ["peer0", "peer1"],
          },
        ],
      },
    ],
    chaincodes: [],
    hooks: {},
  };
}

export function parseOverrideValue(raw: string): unknown {
  const trimmed = raw.trim();
  if ((trimmed.startsWith('"') && trimmed.endsWith('"')) || (trimmed.startsWith("'") && trimmed.endsWith("'"))) {
    return trimmed.slice(1, -1);
  }

  const lower = trimmed.toLowerCase();

  if (lower === "true") return true;
  if (lower === "false") return false;
  if (lower === "null") return null;

  if (/^-?(0|[1-9]\d*)(\.\d+)?$/.test(trimmed)) {
    return Number(trimmed);
  }

  return trimmed;
}

export function applyOverride(
  config: FabloConfigJson,
  rawPath: string,
  rawValue: string,
  log: (msg: string) => void,
): void {
  const dottedPath = rawPath.replace(/\[(\d+)\]/g, ".$1");
  const value = parseOverrideValue(rawValue);
  _.set(config, dottedPath, value);

  const displayValue = typeof value === "string" ? value : JSON.stringify(value);
  log(chalk.blue(`ℹ Dynamic override: ${dottedPath} = ${displayValue}`));
}

function validateFabloConfig(configToValidate: FabloConfigJson): string[] {
  const validator = new SchemaValidator();
  const results = validator.validate(configToValidate, schema);
  return results.errors.map((error) => `${error.property}: ${error.message}`);
}

export default class Init extends Command {
  static override description =
    "Creates simple Fablo config in current directory with optional Node.js, chaincode, REST API and dev mode";

  static args = {
    options: Args.string({
      multiple: true,
      required: false,
      description: "Options: node, dev, ccaas, gateway, rest (order does not matter)",
    }),
  };

  static flags = {
    set: Flags.string({
      multiple: true,
      summary: "Override config values",
    }),
  };

  static strict = false;

  private getEffectiveFlags(args: { options?: string[] | string }): {
    node: boolean;
    dev: boolean;
    ccaas: boolean;
    gateway: boolean;
    rest: boolean;
  } {
    const validOptions = ["node", "dev", "ccaas", "gateway", "rest"] as const;
    const optionsArr = Array.isArray(args?.options) ? args.options : args?.options ? [args.options] : [];
    const raw = optionsArr.filter((s) => !s.startsWith("-")).map((s) => s.toLowerCase());
    const invalid = raw.filter((o) => !validOptions.includes(o as (typeof validOptions)[number]));
    if (invalid.length > 0) {
      this.error(`Unknown options: ${invalid.join(", ")}. Valid: ${validOptions.join(", ")}`);
    }
    return {
      node: raw.includes("node"),
      dev: raw.includes("dev"),
      ccaas: raw.includes("ccaas"),
      gateway: raw.includes("gateway"),
      rest: raw.includes("rest"),
    };
  }

  async copySampleConfig(): Promise<void> {
    let fabloConfigJson = getDefaultFabloConfig();
    const parsed = await this.parse(Init);
    const argv = (parsed.argv ?? []) as string[];

    const unsupportedArgs = argv.filter((arg) => arg.startsWith("--"));
    if (unsupportedArgs.length > 0) {
      this.error("Unsupported override syntax. Use --set <path>=<value>.");
    }
    const flags = this.getEffectiveFlags({ options: argv });
    if (flags.ccaas) {
      if (flags.dev || flags.node) {
        this.log(chalk.red("Error: ccaas cannot be used together with dev or node"));
        process.exit(1);
      }
      this.log("Creating sample CCAAS chaincode");

      const chaincodeConfig: ChaincodeJson = {
        name: "chaincode1",
        version: "0.0.1",
        channel: "my-channel1",
        lang: "ccaas",
        image: "ghcr.io/fablo-io/fablo-sample-kv-node-chaincode:2.2.0",
        chaincodeStartCommand: "npm run start:ccaas",
        privateData: [],
      };
      fabloConfigJson = {
        ...fabloConfigJson,
        chaincodes: [...fabloConfigJson.chaincodes, chaincodeConfig],
      };
    }
    if (flags.node) {
      console.log("Creating sample Node.js chaincode");

      const source = path.join(__dirname, "../../../samples/chaincodes/chaincode-kv-node");
      const destination = path.join(process.cwd(), "chaincodes/chaincode-kv-node");
      fs.copySync(source, destination);

      fs.writeFileSync(path.join(destination, ".nvmrc"), "12");

      // force build on Node 12, since dev deps (@theledger/fabric-mock-stub) may not work on 16
      // fs.write(destination("chaincodes/chaincode-kv-node/.nvmrc"), "12");

      const chaincodeConfig: ChaincodeJson = flags.dev
        ? {
            name: "chaincode1",
            version: "0.0.1",
            channel: "my-channel1",
            lang: "ccaas",
            image: "hyperledger/fabric-nodeenv:${FABRIC_NODEENV_VERSION:-2.5}",
            chaincodeMountPath: "$CHAINCODES_BASE_DIR/chaincodes/chaincode-kv-node",
            chaincodeStartCommand: "npm run start:watch:ccaas",
            privateData: [],
          }
        : {
            name: "chaincode1",
            version: "0.0.1",
            channel: "my-channel1",
            lang: "node",
            directory: "./chaincodes/chaincode-kv-node",
            privateData: [],
          };

      const postGenerateHook = flags.dev ? { postGenerate: "npm i --prefix ./chaincodes/chaincode-kv-node" } : {};

      fabloConfigJson = {
        ...fabloConfigJson,
        chaincodes: [...fabloConfigJson.chaincodes, chaincodeConfig],
        hooks: { ...fabloConfigJson.hooks, ...postGenerateHook },
      };
    }

    if (flags.gateway) {
      console.log("Creating sample Node.js gateway");

      const src = path.join(__dirname, "../../../samples/gateway");
      const dest = path.join(process.cwd(), "gateway");
      fs.copySync(src, dest);
      this.log("✔ Gateway generated successfully!");
    }

    if (flags.rest) {
      const orgs = fabloConfigJson.orgs.map((org: OrgJson) => ({ ...org, tools: { fabloRest: true } }));
      fabloConfigJson = { ...fabloConfigJson, orgs };
    }

    const global: GlobalJson = {
      ...fabloConfigJson.global,
      engine: fabloConfigJson.global.engine ?? "docker",
    };
    fabloConfigJson = { ...fabloConfigJson, global };

    if (parsed.flags.set) {
      for (const setValue of parsed.flags.set) {
        const eqIndex = setValue.indexOf("=");
        if (eqIndex === -1) {
          this.error(`Invalid --set format: ${setValue}. Expected key=value`);
        }
        const configPath = setValue.slice(0, eqIndex);
        const rawValue = setValue.slice(eqIndex + 1);
        applyOverride(fabloConfigJson, configPath, rawValue, (msg) => this.log(msg));
      }
    }

    const validationErrors = validateFabloConfig(fabloConfigJson);
    if (validationErrors.length > 0) {
      const message =
        "Validation of final configuration failed:\n" + validationErrors.map((e) => `  - ${e}`).join("\n");
      this.error(message);
    }

    const rootPath = process.cwd();
    const outputFile = path.join(rootPath, "fablo-config.json");
    // fs.write(this.destinationPath("fablo-config.json"), JSON.stringify(fabloConfigJson, undefined, 2));
    fs.writeFileSync(outputFile, JSON.stringify(fabloConfigJson, null, 2));

    this.log("===========================================================");
    this.log(chalk.bold("Sample config file created! :)"));
    this.log("You can start your network with 'fablo up' command");
    this.log("===========================================================");
  }

  public async run(): Promise<void> {
    await this.copySampleConfig();
  }
}
