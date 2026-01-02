import { Command, Flags } from '@oclif/core'
import * as chalk from "chalk";
import { GlobalJson, FabloConfigJson, ChaincodeJson } from "../../types/FabloConfigJson";
import * as path from 'path';
import * as fs from 'fs-extra';
import { version } from "../../../package.json";
import { printSplash } from '../../fablolog';

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

  static flags = {
    node: Flags.boolean({ description: 'Include Node.js chaincode sample' }),
    dev: Flags.boolean({ description: 'Enable dev mode (dev chaincodes)' }),
    ccaas: Flags.boolean({ description: 'Include CCAAS chaincode sample' }),
    gateway: Flags.boolean({ description: 'Include Gateway app sample' }),
    rest: Flags.boolean({ description: 'Include REST API sample' }),
  };

  async copySampleConfig(): Promise<void> {
    let fabloConfigJson = getDefaultFabloConfig();
    const { flags } = await this.parse(Init);

    console.log("init flags: ", JSON.stringify(flags, null, 2));

    if (flags.ccaas) {
      if (flags.dev || flags.node) {
        this.log(chalk.red("Error: --ccaas flag cannot be used together with --dev or --node flags"));
        process.exit(1);
      }
      this.log("Creating sample CCAAS chaincode");
      printSplash();

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
      printSplash();
      const source = path.join(__dirname, '../../../../samples/chaincodes/chaincode-kv-node');
      const destination = path.join(process.cwd(), 'chaincodes');
      fs.copySync(source, destination);

      // fs.copySync(source, path.join(process.cwd(), 'chaincodes'));
      fs.writeFileSync(path.join(process.cwd(), 'samples/chaincodes/chaincode-kv-node/.nvmrc'), '12');

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
      printSplash();
      const src = path.join(__dirname, '../../../../samples/gateway');
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
    this.log("You can start your network with 'fablo up' command");
    this.log("===========================================================");

  }

  public async run(): Promise<void> {

    await this.copySampleConfig();
  }
}
