import { Args, Command, Flags } from "@oclif/core";
import * as chalk from "chalk";
import { GlobalJson, FabloConfigJson, ChaincodeJson } from "../../types/FabloConfigJson";
import { Validator as SchemaValidator } from "jsonschema";
import * as _ from "lodash";
import * as path from "path";
import * as fs from "fs-extra";
import { version } from "../../../package.json";
import { schema } from "../../config";

const SENSITIVE_PATH_PARTS = new Set([
  "password",
  "secret",
  "token",
  "apikey",
  "api_key",
  "private",
  "credential",
  "cert",
  "certificate",
  "key",
]);

function splitPathTokens(pathValue: string): string[] {
  return pathValue
    .replace(/([a-z0-9])([A-Z])/g, "$1 $2")
    .split(/[^a-zA-Z0-9]+/g)
    .filter(Boolean)
    .map((part) => part.toLowerCase());
}

function isSensitiveOverridePath(pathValue: string): boolean {
  return splitPathTokens(pathValue).some((part) => SENSITIVE_PATH_PARTS.has(part));
}

function formatOverrideValue(pathValue: string, value: unknown): string {
  if (isSensitiveOverridePath(pathValue)) {
    return "********";
  }
  if (typeof value === "string") {
    return value;
  }
  return JSON.stringify(value);
}

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

// Parse override string value to boolean, null, number, JSON, or fallback to string.
export function parseOverrideValue(raw: string): unknown {
  const trimmed = raw.trim();
  // quoted strings – strip quotes and treat content as string
  if ((trimmed.startsWith('"') && trimmed.endsWith('"')) || (trimmed.startsWith("'") && trimmed.endsWith("'"))) {
    return trimmed.slice(1, -1);
  }

  const lower = trimmed.toLowerCase();

  if (lower === "true") return true;
  if (lower === "false") return false;
  if (lower === "null") return null;

  // JSON object / array
  if (trimmed.startsWith("{") || trimmed.startsWith("[")) {
    try {
      return JSON.parse(trimmed);
    } catch {
      return trimmed;
    }
  }

  // number – only plain decimal integers / floats (no leading zeros except for "0")
  if (/^-?(0|[1-9]\d*)(\.\d+)?$/.test(trimmed) && trimmed !== "") {
    return Number(trimmed);
  }

  // fallback: keep as string
  return trimmed;
}

// Apply a single override to config, normalising bracket notation to dots.
export function applyOverride(
  config: FabloConfigJson,
  rawPath: string,
  rawValue: string,
  log: (msg: string) => void,
): void {
  const dottedPath = rawPath.replace(/\[(\d+)\]/g, ".$1");
  const value = parseOverrideValue(rawValue);
  _.set(config, dottedPath, value);

  log(chalk.blue(`ℹ Dynamic override: ${dottedPath} = ${formatOverrideValue(dottedPath, value)}`));
}

// Validate the config object against the Fablo schema.
function validateFabloConfig(configToValidate: FabloConfigJson): string[] {
  const validator = new SchemaValidator();
  const results = validator.validate(configToValidate, schema);
  return results.errors.map((error) => `${error.property}: ${error.message}`);
}


export default class Init extends Command {
  static override description =
    "Creates simple Fablo config in current directory with optional Node.js, chaincode, REST API and dev mode";

  static ["--"] = false;
  static args = {
    options: Args.string({
      multiple: true,
      required: false,
      description: 'Options: node, dev, ccaas, gateway, rest (order does not matter)',
    }),
  };

  static flags = {
    set: Flags.string({
      multiple: true,
      summary: 'Override config values',
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
    const validOptions = ['node', 'dev', 'ccaas', 'gateway', 'rest'] as const;
    const optionsArr = Array.isArray(args?.options) ? args.options : args?.options ? [args.options] : [];
    const raw = optionsArr.filter((s) => !s.startsWith("-")).map((s) => s.toLowerCase());
    const invalid = raw.filter((o) => !validOptions.includes(o as (typeof validOptions)[number]));
    if (invalid.length > 0) {
      this.error(`Unknown options: ${invalid.join(', ')}. Valid: ${validOptions.join(', ')}`);
    }
    return {
      node: raw.includes('node'),
      dev: raw.includes('dev'),
      ccaas: raw.includes('ccaas'),
      gateway: raw.includes('gateway'),
      rest: raw.includes('rest'),
    };
  }

  async copySampleConfig(): Promise<void> {
    // 1. generate base config
    let fabloConfigJson = getDefaultFabloConfig();
    const parsed = await this.parse(Init);
    const argv = (parsed.argv ?? []) as string[];

    // 2. check for raw overrides (which are unsupported)
    const unsupportedArgs = argv.filter((arg) => arg.startsWith("--"));
    if (unsupportedArgs.length > 0) {
      this.error("Unsupported override syntax. Use --set <path>=<value>.");
    }

    // 3. extract flags (node, dev, ccaas, gateway, rest) from positional arguments
    const flags = this.getEffectiveFlags({ options: argv });

    // 4. apply built-in modifications first
    if (flags.ccaas) {
      if (flags.dev || flags.node) {
        this.error(chalk.red("Error: ccaas cannot be used together with dev or node"));
      }
      this.log("Creating sample CCAAS chaincode");

      const chaincodeConfig: ChaincodeJson = {
        name: "chaincode1",
        version: "0.0.1",
        channel: "my-channel1",
        lang: "ccaas",
        image: "ghcr.io/fablo-io/fablo-sample-kv-node-chaincode:2.2.0",
        privateData: [],
      };
      fabloConfigJson = {
        ...fabloConfigJson,
        chaincodes: [...fabloConfigJson.chaincodes, chaincodeConfig],
      };
    }

    if (flags.node) {
      this.log("Creating sample Node.js chaincode");

      const source = path.join(__dirname, "../../../samples/chaincodes/chaincode-kv-node");
      const destination = path.join(process.cwd(), "chaincodes/chaincode-kv-node");
      fs.copySync(source, destination);

      fs.writeFileSync(path.join(destination, ".nvmrc"), "12");

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
      this.log('Creating sample Node.js gateway');

      const src = path.join(__dirname, '../../../samples/gateway');
      const dest = path.join(process.cwd(), 'gateway');
      fs.copySync(src, dest);
      this.log('✔ Gateway generated successfully!');
    }

    if (flags.rest) {
      const orgs = fabloConfigJson.orgs.map((org: any) => ({ ...org, tools: { fabloRest: true } }));
      fabloConfigJson = { ...fabloConfigJson, orgs };
    }


    const global: GlobalJson = {
      ...fabloConfigJson.global,
      engine: fabloConfigJson.global.engine ?? "docker",
    };
    fabloConfigJson = { ...fabloConfigJson, global };

    // apply all `--set` overrides AFTER all built-in modifications
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

    // validate final config – if invalid, report errors and stop
    const validationErrors = validateFabloConfig(fabloConfigJson);
    if (validationErrors.length > 0) {
      const message =
        "Validation of final configuration failed:\n" + validationErrors.map((e) => `  - ${e}`).join("\n");
      this.error(message);
    }

    // write config file
    const rootPath = process.cwd();
    const outputFile = path.join(rootPath, "fablo-config.json");
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
