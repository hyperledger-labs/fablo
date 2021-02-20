const { JSONSerializer } = require('fabric-contract-api');
const { ChaincodeMockStub } = require('@theledger/fabric-mock-stub');
const ChaincodeFromContract = require('fabric-shim/lib/contract-spi/chaincodefromcontract');
const uuid = require('uuid');
const { contracts } = require('./index');

const [KVContract] = contracts;

const getChaincodeForContract = (contract) => {
  const serializers = {
    serializers: {
      jsonSerializer: JSONSerializer,
    },
    transaction: 'jsonSerializer',
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
    const transientMap = !transient
      ? undefined
      : Object.keys(transient).reduce((map, k) => map.set(k, transient[k]), new Map());
    const { payload } = await this.mockInvoke(uuid.v1(), args, transientMap);
    return JSON.parse(payload.toString());
  }
}

describe('KVContract', () => {
  it('should put and get value', async () => {
    // Given
    const stub = new KVContractMockStub();
    const key = 'ship';
    const value = 'Black Pearl';

    // When
    const putResponse = await stub.mockInvokeJson(['put', key, value]);
    const getResponse = await stub.mockInvokeJson(['get', key]);

    // Then
    expect(putResponse).toEqual({ success: 'OK' });
    expect(getResponse).toEqual({ success: 'Black Pearl' });
  });

  it('should return missing value error', async () => {
    // Given
    const stub = new KVContractMockStub();
    const key = 'ship';

    // When
    const getResponse = await stub.mockInvokeJson(['get', key]);

    // Then
    expect(getResponse).toEqual({ error: 'NOT_FOUND' });
  });

  it('should get value history', async () => {
    // Given
    const stub = new KVContractMockStub();
    const key = 'ship';
    const value1 = 'Black Pearl';
    const value2 = 'Green Pearl';
    await stub.mockInvokeJson(['put', key, value1]);
    await stub.mockInvokeJson(['put', key, value2]);

    const historyElemMatcher = (value) => ({
      isDelete: false,
      timestamp: expect.stringContaining(new Date().toISOString().slice(0, 10)),
      txId: expect.stringMatching(/.*/),
      value,
    });

    // When
    const response = await stub.mockInvokeJson(['getHistory', key]);

    // Then
    expect(response).toEqual({ success: [historyElemMatcher(value1), historyElemMatcher(value2)] });
  });

  it('should put private data', async () => {
    // Given
    const stub = new KVContractMockStub();
    const key = 'diary';
    const details = 'Black Pearl was initially owned by Jack Sparrow';

    // When
    const response = await stub.mockInvokeJson(['putPrivate', key], { details });

    // Then
    expect(response).toEqual({ success: 'OK' });
  });

  it('should verify private data', async () => {
    // Given
    const stub = new KVContractMockStub();
    const key = 'diary';
    const details = 'Black Pearl was initially owned by Jack Sparrow';
    await stub.mockInvokeJson(['putPrivate', key], { details });

    // When
    const validResponse = await stub.mockInvokeJson(['verifyPrivate', key], { details });
    const invalidResponse = await stub.mockInvokeJson(['verifyPrivate', key], { details: 'Owned by Willy Wonka' });

    // Then
    expect(validResponse).toEqual({ success: 'OK' });
    expect(invalidResponse).toEqual({ success: 'OK' });
  });
});
