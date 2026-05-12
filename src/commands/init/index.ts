import { Args, Command } from '@oclif/core'
import * as chalk from "chalk";
import { GlobalJson, FabloConfigJson, ChaincodeJson } from "../../types/FabloConfigJson";
import * as path from 'path';
import * as fs from 'fs-extra';
import { version } from "../../../package.json";

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

export default class Init extends Command {
  static override description =
    "Creates simple Fablo config in current directory with optional Node.js, chaincode, REST API and dev mode";

  static args = {
    options: Args.string({
      multiple: true,
      required: false,
      description: 'Options: node, dev, ccaas, gateway, rest (order does not matter)',
    }),
  };

  static strict = false;

  private getEffectiveFlags(args: { options?: string[] | string }): { node: boolean; dev: boolean; ccaas: boolean; gateway: boolean; rest: boolean } {
    const validOptions = ['node', 'dev', 'ccaas', 'gateway', 'rest'] as const;
    const optionsArr = Array.isArray(args?.options) ? args.options : args?.options ? [args.options] : [];
    const raw = optionsArr.map((s) => s.toLowerCase());
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
  let fabloConfigJson = getDefaultFabloConfig();
  const parsed = await this.parse(Init);
  const flags = this.getEffectiveFlags({ 
    options: (parsed.argv ?? []) as string[] 
  });

  if (flags.ccaas) {
    if (flags.dev || flags.node) {
      this.error("ccaas cannot be used together with dev or node");
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

    const source = path.join(
      __dirname, 
      '../../../samples/chaincodes/chaincode-kv-node'
    );
    const destination = path.join(
      process.cwd(), 
      'chaincodes/chaincode-kv-node'
    );

    try {
      fs.copySync(source, destination);
    } catch (err) {
      this.error(
        `Failed to copy Node.js chaincode sample from '${source}' to '${destination}': ${(err as Error).message}`
      );
    }

    try {
      fs.writeFileSync(path.join(destination, '.nvmrc'), '12');
    } catch (err) {
      this.error(
        `Failed to write .nvmrc file: ${(err as Error).message}`
      );
    }

    const chaincodeConfig: ChaincodeJson = flags.dev
      ? {
          name: "chaincode1",
          version: "0.0.1",
          channel: "my-channel1",
          lang: "ccaas",
          image: "hyperledger/fabric-nodeenv:${FABRIC_NODEENV_VERSION:-2.5}",
          chaincodeMountPath: 
            "$CHAINCODES_BASE_DIR/chaincodes/chaincode-kv-node",
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

    const postGenerateHook = flags.dev 
      ? { postGenerate: "npm i --prefix ./chaincodes/chaincode-kv-node" } 
      : {};

    fabloConfigJson = {
      ...fabloConfigJson,
      chaincodes: [...fabloConfigJson.chaincodes, chaincodeConfig],
      hooks: { ...fabloConfigJson.hooks, ...postGenerateHook },
    };
  }

  if (flags.gateway) {
    this.log("Creating sample Node.js gateway");

    const src = path.join(__dirname, '../../../samples/gateway');
    const dest = path.join(process.cwd(), 'gateway');

    try {
      fs.copySync(src, dest);
    } catch (err) {
      this.error(
        `Failed to copy gateway sample: ${(err as Error).message}`
      );
    }

    this.log('✔ Gateway generated successfully!');
  }

  if (flags.rest) {
    const orgs = fabloConfigJson.orgs.map((org) => ({ 
      ...org, 
      tools: { fabloRest: true } 
    }));
    fabloConfigJson = { ...fabloConfigJson, orgs };
  }

  const engine = "docker";
  const global: GlobalJson = { ...fabloConfigJson.global, engine };
  fabloConfigJson = { ...fabloConfigJson, global };

  const rootPath = process.cwd();
  const outputFile = path.join(rootPath, 'fablo-config.json');

  try {
    fs.writeFileSync(outputFile, JSON.stringify(fabloConfigJson, null, 2));
  } catch (err) {
    this.error(
      `Failed to write fablo-config.json: ${(err as Error).message}`
    );
  }

  this.log("===========================================================");
  this.log(chalk.bold("Sample config file created! :)"));
  this.log("You can start your network with 'fablo up' command");
  this.log("===========================================================");
}

  public async run(): Promise<void> {

    await this.copySampleConfig();
  }
}
