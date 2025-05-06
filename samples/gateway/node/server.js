import * as grpc from '@grpc/grpc-js';
import { connect, hash, signers } from '@hyperledger/fabric-gateway';
import * as crypto from 'node:crypto';
import { promises as fs } from 'node:fs';
import { TextDecoder } from 'node:util';

const utf8Decoder = new TextDecoder();

async function connection() {
  const credentials = await fs.readFile(process.env.CREDENTIALS);  
  const privateKeyPem = await fs.readFile(process.env.PRIVATE_KEY_PEM);
  const privateKey = crypto.createPrivateKey(privateKeyPem);
  const signer = signers.newPrivateKeySigner(privateKey);  
  const tlsRootCert = await fs.readFile(
    process.env.TLS_ROOT_CERT,
  );
  const client = new grpc.Client(process.env.PEER_GATEWAY_URL, grpc.credentials.createSsl(tlsRootCert), {
    "grpc.ssl_target_name_override": process.env.PEER_ORG_NAME,
  });  
  const gateway = connect({
    identity: { mspId: process.env.MSP_ID, credentials },
    signer,
    hash: hash.sha256,
    client,
  });  
  try {
    const network = gateway.getNetwork(process.env.CHANNEL_NAME);
    const contract = network.getContract(process.env.CONTRACT_NAME);  
    const putResult = await contract.submitTransaction('put', 'time', new Date().toISOString());
    console.log('Put result:', utf8Decoder.decode(putResult));  
    const getResult = await contract.evaluateTransaction('get', 'time');
    console.log('Get result:', utf8Decoder.decode(getResult));
  } finally {
    gateway.close();
    client.close();
  }
}

connection().catch(console.error);

