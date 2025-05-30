import * as Generator from "yeoman-generator";
import * as chalk from "chalk";
import { GlobalJson, FabloConfigJson } from "../types/FabloConfigJson";

function getDefaultFabloConfig(): FabloConfigJson {
  return {
  $schema: "https://github.com/hyperledger-labs/fablo/releases/download/2.2.0/schema.json",
  global: {
    fabricVersion: "2.5.9",
    tls: false,
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
          type: "solo",
          instances: 1,
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
  chaincodes: [
    {
      name: "chaincode1",
      version: "0.0.1",
      lang: "node",
      channel: "my-channel1",
      directory: "./chaincodes/chaincode-kv-node",
      privateData: [],
    },
  ],
  hooks: {},
 };
}

export default class InitGenerator extends Generator {
  constructor(readonly args: string[], opts: Generator.GeneratorOptions) {
    super(args, opts);
  }

  async copySampleConfig(): Promise<void> {
    let fabloConfigJson = getDefaultFabloConfig();

    const shouldInitWithNodeChaincode = this.args.length && this.args.find((v) => v === "node");
    if (shouldInitWithNodeChaincode) {
      console.log("Creating sample Node.js chaincode");
      this.fs.copy(this.templatePath("chaincodes"), this.destinationPath("chaincodes"));
      // force build on Node 12, since dev deps (@theledger/fabric-mock-stub) may not work on 16
      this.fs.write(this.destinationPath("chaincodes/chaincode-kv-node/.nvmrc"), "12");
    } else {
      fabloConfigJson = { ...fabloConfigJson, chaincodes: [] };
    }

    const shouldAddFabloRest = this.args.length && this.args.find((v) => v === "rest");
    if (shouldAddFabloRest) {
      const orgs = fabloConfigJson.orgs.map((org) => ({ ...org, tools: { fabloRest: true } }));
      fabloConfigJson = { ...fabloConfigJson, orgs };
    } else {
      const orgs = fabloConfigJson.orgs.map((org) => ({ ...org, tools: {} }));
      fabloConfigJson = { ...fabloConfigJson, orgs };
    }

    const shouldUseKubernetes = this.args.length && this.args.find((v) => v === "kubernetes" || v === "k8s");
    const shouldRunInDevMode = this.args.length && this.args.find((v) => v === "dev");
    const global: GlobalJson = {
      ...fabloConfigJson.global,
      engine: shouldUseKubernetes ? "kubernetes" : "docker",
      peerDevMode: !!shouldRunInDevMode,
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