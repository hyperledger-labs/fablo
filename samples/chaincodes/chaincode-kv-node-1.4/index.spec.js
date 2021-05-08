const { JSONSerializer } = require("fabric-contract-api");
const { ChaincodeMockStub } = require("@theledger/fabric-mock-stub");
const ChaincodeFromContract = require("fabric-shim/lib/contract-spi/chaincodefromcontract");
const uuid = require("uuid");
const { contracts } = require("./index");

const [KVContract] = contracts;

const getChaincodeForContract = (contract) => {
  const serializers = {
    serializers: {
      jsonSerializer: JSONSerializer,
    },
    transaction: "jsonSerializer",
  };
  return new ChaincodeFromContract([contract], serializers, { info: {} });
};

class KVContractMockStub extends ChaincodeMockStub {
  constructor() {
    super(KVContract.toString(), getChaincodeForContract(KVContract));
  }

  getBufferArgs() {
    return this.getArgs().map((x) => Buffer.from(x));
  }

  async mockInvokeJson(args, transient) {
    const transientMap = Object.keys(transient || {}).reduce((map, k) => map.set(k, transient[k]), new Map());
    const response = await this.mockInvoke(uuid.v1(), args, transientMap);

    if (response.status !== 200) {
      console.error(`Error invoking chaincode. Status: ${response.status}, message:`, response.message);
      throw response.message;
    }

    return JSON.parse(response.payload.toString());
  }
}

describe("KVContract", () => {
  it("should put and get value", async () => {
    // Given
    const stub = new KVContractMockStub();
    const key = "ship";
    const value = "Black Pearl";

    // When
    const putResponse = await stub.mockInvokeJson(["put", key, value]);
    const getResponse = await stub.mockInvokeJson(["get", key]);

    // Then
    expect(putResponse).toEqual({ success: "OK" });
    expect(getResponse).toEqual({ success: "Black Pearl" });
  });

  it("should return missing value error", async () => {
    // Given
    const stub = new KVContractMockStub();
    const key = "ship";

    // When
    const getResponse = await stub.mockInvokeJson(["get", key]);

    // Then
    expect(getResponse).toEqual({ error: "NOT_FOUND" });
  });

  it("should put private data", async () => {
    // Given
    const stub = new KVContractMockStub();
    const key = "diary";
    const message = "Black Pearl was initially owned by Jack Sparrow";

    // When
    const response = await stub.mockInvokeJson(["putPrivateMessage", key], { message });

    // Then
    expect(response).toEqual({ success: "OK" });
  });

  // Just for the reference. Method 'getPrivateDataHash' is not implemented in @theledger/fabric-mock-stub lib
  it.skip("should verify private data", async () => {
    // Given
    const stub = new KVContractMockStub();
    const key = "diary";
    const message = { message: "Black Pearl was initially owned by Jack Sparrow" };
    const wrongMessage = { message: "Owned by Willy Wonka" };
    await stub.mockInvokeJson(["putPrivateMessage", key], message);

    // When
    const validResponse = await stub.mockInvokeJson(["verifyPrivateMessage", key], message);
    const invalidResponse = await stub.mockInvokeJson(["verifyPrivateMessage", key], wrongMessage);

    // Then
    expect(validResponse).toEqual({ success: "OK" });
    expect(invalidResponse).toEqual({ success: "OK" });
  });
});
