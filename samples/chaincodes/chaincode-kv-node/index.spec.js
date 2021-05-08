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

const creatorMock = {
  mspid: "MockTestOrgMSP",
  idBytes: Buffer.from(`-----BEGIN CERTIFICATE-----
MIIExDCCA6ygAwIBAgIJAK0JmDc/YXWsMA0GCSqGSIb3DQEBBQUAMIGcMQswCQYD
VQQGEwJJTjELMAkGA1UECBMCQVAxDDAKBgNVBAcTA0hZRDEZMBcGA1UEChMQUm9j
a3dlbGwgY29sbGluczEcMBoGA1UECxMTSW5kaWEgRGVzaWduIENlbnRlcjEOMAwG
A1UEAxMFSU1BQ1MxKTAnBgkqhkiG9w0BCQEWGmJyYWphbkBSb2Nrd2VsbGNvbGxp
bnMuY29tMB4XDTExMDYxNjE0MTQyM1oXDTEyMDYxNTE0MTQyM1owgZwxCzAJBgNV
BAYTAklOMQswCQYDVQQIEwJBUDEMMAoGA1UEBxMDSFlEMRkwFwYDVQQKExBSb2Nr
d2VsbCBjb2xsaW5zMRwwGgYDVQQLExNJbmRpYSBEZXNpZ24gQ2VudGVyMQ4wDAYD
VQQDEwVJTUFDUzEpMCcGCSqGSIb3DQEJARYaYnJhamFuQFJvY2t3ZWxsY29sbGlu
cy5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDfjHgUAsbXQFkF
hqv8OTHSzuj+8SKGh49wth3UcH9Nk/YOug7ZvI+tnOcrCZdeG2Ot8Y19Wusf59Y7
q61jSbDWt+7u7P0ylWWcQfCE9IHSiJIaKAklMu2qGB8bFSPqDyVJuWSwcSXEb9C2
xJsabfgJr6mpfWjCOKd58wFprf0RF58pWHyBqBOiZ2U20PKhq8gPJo/pEpcnXTY0
x8bw8LZ3SrrIQZ5WntFKdB7McFKG9yFfEhUamTKOffQ2Y+SDEGVDj3eshF6+Fxgj
8plyg3tZPRLSHh5DR42HTc/35LA52BvjRMWYzrs4nf67gf652pgHh0tFMNMTMgZD
rpTkyts9AgMBAAGjggEFMIIBATAdBgNVHQ4EFgQUG0cLBjouoJPM8dQzKUQCZYNY
y8AwgdEGA1UdIwSByTCBxoAUG0cLBjouoJPM8dQzKUQCZYNYy8ChgaKkgZ8wgZwx
CzAJBgNVBAYTAklOMQswCQYDVQQIEwJBUDEMMAoGA1UEBxMDSFlEMRkwFwYDVQQK
ExBSb2Nrd2VsbCBjb2xsaW5zMRwwGgYDVQQLExNJbmRpYSBEZXNpZ24gQ2VudGVy
MQ4wDAYDVQQDEwVJTUFDUzEpMCcGCSqGSIb3DQEJARYaYnJhamFuQFJvY2t3ZWxs
Y29sbGlucy5jb22CCQCtCZg3P2F1rDAMBgNVHRMEBTADAQH/MA0GCSqGSIb3DQEB
BQUAA4IBAQCyYZxEzn7203no9TdhtKDWOFRwzYvY2kZppQ/EpzF+pzh8LdBOebr+
DLRXNh2NIFaEVV0brpQTI4eh6b5j7QyF2UmA6+44zmku9LzS9DQVKGLhIleB436K
ARoWRqxlEK7TF3TauQfaalGH88ZWoDjqqEP/5oWeQ6pr/RChkCHkBSgq6FfGGSLd
ktgFcF0S9U7Ybii/MD+tWMImK8EE3GGgs876yqX/DDhyfW8DfnNZyl35VF/80j/s
0Lj3F7Po1zsaRbQlhOK5rzRVQA2qnsa4IcQBuYqBWiB6XojPgu9PpRSL7ure7sj6
gRQT0OIU5vXzsmhjqKoZ+dBlh1FpSOX2
-----END CERTIFICATE-----`),
};

class KVContractMockStub extends ChaincodeMockStub {
  constructor() {
    super(KVContract.toString(), getChaincodeForContract(KVContract));
  }

  getBufferArgs() {
    return this.getArgs().map((x) => Buffer.from(x));
  }

  getCreator() {
    return creatorMock;
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
