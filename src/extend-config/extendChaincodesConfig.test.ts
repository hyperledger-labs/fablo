import extendConfig from "./extendConfig";
import { FabloConfigJson } from "../types/FabloConfigJson";

describe("extendChaincodesConfig CCaaS package labels", () => {
  it("should share package labels across peers in the same org and separate them across orgs", () => {
    const config: FabloConfigJson = {
      $schema: "https://github.com/hyperledger-labs/fablo/releases/download/2.6.0/schema.json",
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
              prefix: "orderer",
              type: "raft",
              instances: 1,
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
            prefix: "peer",
            instances: 2,
            db: "LevelDb",
          },
        },
        {
          organization: {
            name: "Org2",
            domain: "org2.example.com",
            mspName: "Org2MSP",
          },
          ca: {
            prefix: "ca",
            db: "sqlite",
          },
          orderers: [],
          peer: {
            prefix: "peer",
            instances: 1,
            db: "LevelDb",
          },
        },
      ],
      channels: [
        {
          name: "my-channel1",
          orgs: [
            { name: "Org1", peers: ["peer0", "peer1"] },
            { name: "Org2", peers: ["peer0"] },
          ],
        },
      ],
      chaincodes: [
        {
          name: "chaincode1",
          version: "0.0.1",
          lang: "ccaas",
          channel: "my-channel1",
          image: "ghcr.io/fablo-io/fablo-sample-kv-node-chaincode:2.2.0",
          privateData: [],
        },
      ],
      hooks: {},
    };

    const [chaincode] = extendConfig(config).chaincodes;
    const packageLabelsByPeer = chaincode.peerChaincodeInstances?.map(({ peerAddress, packageLabel }) => ({
      peerAddress,
      packageLabel,
    }));

    expect(packageLabelsByPeer).toEqual([
      { peerAddress: "peer0.org1.example.com", packageLabel: "Org1_my-channel1_chaincode1_0.0.1" },
      { peerAddress: "peer1.org1.example.com", packageLabel: "Org1_my-channel1_chaincode1_0.0.1" },
      { peerAddress: "peer0.org2.example.com", packageLabel: "Org2_my-channel1_chaincode1_0.0.1" },
    ]);
  });
});
