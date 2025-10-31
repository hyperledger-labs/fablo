import * as Generator from "yeoman-generator";
import * as chalk from "chalk";
import { GlobalJson, FabloConfigJson, ChaincodeJson } from "../types/FabloConfigJson";
import { version } from "../../package.json";

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

export default class InitGenerator extends Generator {
  constructor(readonly args: string[], opts: Generator.GeneratorOptions) {
    super(args, opts);
  }

  async copySampleConfig(): Promise<void> {
    let fabloConfigJson = getDefaultFabloConfig();

    const flags: Record<string, true> = (this.args ?? []).reduce((acc, v) => {
      acc[v] = true;
      return acc;
    }, {} as Record<string, true>);

    if (flags.ccaas) {
      if (flags.dev || flags.node){
        this.log(chalk.red("Error: --ccaas flag cannot be used together with --dev or --node flags"));
        process.exit(1);
      }
      console.log("Creating sample CCAAS chaincode");

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
      this.fs.copy(this.templatePath("chaincodes"), this.destinationPath("chaincodes"));
      // force build on Node 12, since dev deps (@theledger/fabric-mock-stub) may not work on 16
      this.fs.write(this.destinationPath("chaincodes/chaincode-kv-node/.nvmrc"), "12");

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
      this.fs.copy(this.templatePath("gateway"), this.destinationPath("gateway"));
    }

    if (flags.rest) {
      const orgs = fabloConfigJson.orgs.map((org) => ({ ...org, tools: { fabloRest: true } }));
      fabloConfigJson = { ...fabloConfigJson, orgs };
    }

    const engine = flags.kubernetes || flags.k8s ? "kubernetes" : "docker";

    const global: GlobalJson = {
      ...fabloConfigJson.global,
      engine,
    };
    fabloConfigJson = { ...fabloConfigJson, global };

    this.fs.write(this.destinationPath("fablo-config.json"), JSON.stringify(fabloConfigJson, undefined, 2));

    this.on("end", () => {
      console.log("===========================================================");
      console.log(chalk.bold("Sample config file created! :)"));
      console.log("You can start your network with 'fablo up' command");
      console.log("===========================================================");
    });
  }
}
