import { Args, Command } from '@oclif/core'
import * as chalk from "chalk";
import { GlobalJson, FabloConfigJson, ChaincodeJson, FabricXConfigJson } from "../../types/FabloConfigJson";
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

  private getEffectiveFlags(args: { options?: string[] | string }): { node: boolean; dev: boolean; ccaas: boolean; gateway: boolean; rest: boolean; fabricX: boolean } {
    const validOptions = ['node', 'dev', 'ccaas', 'gateway', 'rest', 'fabric-x'] as const;
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
      fabricX: raw.includes('fabric-x'),
    };
  }

  async copySampleConfig(): Promise<void> {
    let fabloConfigJson = getDefaultFabloConfig();
    const parsed = await this.parse(Init);
    const flags = this.getEffectiveFlags({ options: (parsed.argv ?? []) as string[] });

    // Fabric-X mode: generate a completely different config
    if (flags.fabricX) {
      if (flags.node || flags.dev || flags.ccaas || flags.gateway || flags.rest) {
        this.log(chalk.red("Error: fabric-x cannot be combined with node, dev, ccaas, gateway, or rest"));
        process.exit(1);
      }
      this.log("Creating Fabric-X network configuration");
      fabloConfigJson = this._getFabricXConfig();
    }

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
        privateData: [],
      };
      fabloConfigJson = {
        ...fabloConfigJson,
        chaincodes: [...fabloConfigJson.chaincodes, chaincodeConfig],
      };
    }
    if (flags.node) {
      console.log("Creating sample Node.js chaincode");

      const source = path.join(__dirname, '../../../samples/chaincodes/chaincode-kv-node');
      const destination = path.join(process.cwd(), 'chaincodes/chaincode-kv-node');
      fs.copySync(source, destination);

      fs.writeFileSync(
        path.join(destination, '.nvmrc'),
        '12'
      );


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

      const src = path.join(__dirname, '../../../samples/gateway');
      const dest = path.join(process.cwd(), 'gateway');
      fs.copySync(src, dest);
      this.log('✔ Gateway generated successfully!');
    }

    if (flags.rest) {
      const orgs = fabloConfigJson.orgs.map((org) => ({ ...org, tools: { fabloRest: true } }));
      fabloConfigJson = { ...fabloConfigJson, orgs };
    }

    const engine = "docker";

    const global: GlobalJson = {
      ...fabloConfigJson.global,
      engine,
    };
    fabloConfigJson = { ...fabloConfigJson, global };
    const rootPath = process.cwd();
    const outputFile = path.join(rootPath, 'fablo-config.json');
    // fs.write(this.destinationPath("fablo-config.json"), JSON.stringify(fabloConfigJson, undefined, 2));
    fs.writeFileSync(outputFile, JSON.stringify(fabloConfigJson, null, 2));

    this.log("===========================================================");
    this.log(chalk.bold("Sample config file created! :)"));
    if (flags.fabricX) {
      this.log("You can generate your Fabric-X network with 'fablo generate' command");
    } else {
      this.log("You can start your network with 'fablo up' command");
    }
    this.log("===========================================================");

  }

  private _getFabricXConfig(): FabloConfigJson {
    const fabricXDefaults: FabricXConfigJson = {
      version: "0.0.15",
      orderer: {
        routerInstances: 1,
        batcherShards: 1,
        batchersPerShard: 1,
        consenterInstances: 1,
        assemblerInstances: 1,
      },
      committer: {
        instances: 1,
      },
    };

    return {
      $schema: `https://github.com/hyperledger-labs/fablo/releases/download/${version}/schema.json`,
      global: {
        fabricVersion: "3.1.0",
        tls: false,
        peerDevMode: false,
        engine: "fabric-x",
        fabricX: fabricXDefaults,
      },
      orgs: [
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
        },
      ],
      channels: [],
      chaincodes: [],
      hooks: {},
    };
  }

  public async run(): Promise<void> {

    await this.copySampleConfig();
  }
}
