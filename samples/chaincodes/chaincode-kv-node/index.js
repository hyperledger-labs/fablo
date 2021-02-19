const { Contract } = require('fabric-contract-api');

class KVContract extends Contract {
  constructor() {
    super('KVContract');
  }

  async instantiate() {
    // function that will be invoked on chaincode instantiation
  }

  async put(ctx, key, value) {
    await ctx.stub.putState(key, Buffer.from(value));
    return { success: 'OK' };
  }

  async get(ctx, key) {
    const buffer = await ctx.stub.getState(key);
    if (!buffer || !buffer.length) return { error: 'NOT_FOUND' };
    return { success: buffer.toString() };
  }

  async getHistory(ctx, key) {
    const iterator = await ctx.stub.getHistoryForKey(key);
    const results = [];

    for (let i = 0; i < 100; i += 1) { // limit to 100 results
      // eslint-disable-next-line no-await-in-loop
      const next = await iterator.next();
      if (!next || !next.value) break;

      const {
        is_delete: isDelete, value, timestamp, tx_id: txId,
      } = next.value;

      const date = new Date(timestamp.seconds.low * 1000 + timestamp.nanos / 1000000);
      results.push({
        isDelete,
        value: value.toBuffer().toString(),
        timestamp: date.toISOString(),
        txId,
      });
    }

    return { success: results };
  }
}

exports.contracts = [KVContract];
