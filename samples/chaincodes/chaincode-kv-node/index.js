const { Contract } = require('fabric-contract-api');
const crypto = require('crypto');

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

  async putPrivateMessage(ctx, collection) {
    const transient = ctx.stub.getTransient();
    const message = transient.get('message');
    console.log('transient', message);
    await ctx.stub.putPrivateData(collection, 'message', message);
    return { success: 'OK' };
  }

  async verifyPrivateMessage(ctx, collection) {
    const transient = ctx.stub.getTransient();
    const message = transient.get('message').toBuffer().toString();
    console.log('transient', message);

    const currentHash = crypto.createHash('sha256').update(message).digest('hex');
    console.log('hash', currentHash);

    const privateDataHash = (await ctx.stub.getPrivateDataHash(collection, 'message')).toString('hex');
    console.log('private data hash', privateDataHash);

    if (privateDataHash !== currentHash) { return { error: 'VERIFICATION_FAILED' }; }
    return { success: 'OK' };
  }
}

exports.contracts = [KVContract];
