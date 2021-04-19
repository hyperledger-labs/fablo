/* eslint-disable no-param-reassign */

const { matchers } = require('jest-json-schema');
const schema = require('../docs/schema');
const docsSample = require('../docs/sample');

expect.extend(matchers);

describe('schema', () => {
  const base = docsSample;
  expect(base).toMatchSchema(schema);

  const updatedBase = (updateJson) => {
    const json = JSON.parse(JSON.stringify(base));
    updateJson(json);
    return json;
  };

  const lettersOnly = 'lettersonly';
  const underscore = 'under_score';
  const lettersAndNumber = 'lettersand4';
  const uppercase = 'UpperCase';
  const domain = 'domain.example.com';
  const spaces = 'with spaces';
  const specialCharacters1 = 'with!characters';
  const specialCharacters2 = 'withspecial@';

  it('should match snapshot', () => {
    expect(schema).toMatchSnapshot();
  });

  it('should validate fabric version', () => {
    const withFabricVersion = (v) => updatedBase((json) => {
      json.networkSettings.fabricVersion = v;
    });

    expect(withFabricVersion('1.4.3')).toMatchSchema(schema);
    expect(withFabricVersion('1.4.4')).toMatchSchema(schema);
    expect(withFabricVersion('1.3.1')).not.toMatchSchema(schema);
    expect(withFabricVersion('2.0.0')).not.toMatchSchema(schema);
  });

  it('should validate root org name', () => {
    const withRootOrgName = (n) => updatedBase((json) => {
      json.rootOrg.organization.name = n;
    });

    expect(withRootOrgName(lettersOnly)).toMatchSchema(schema);
    expect(withRootOrgName(lettersAndNumber)).toMatchSchema(schema);
    expect(withRootOrgName(uppercase)).toMatchSchema(schema);
    expect(withRootOrgName(domain)).not.toMatchSchema(schema);
    expect(withRootOrgName(spaces)).not.toMatchSchema(schema);
    expect(withRootOrgName(specialCharacters1)).not.toMatchSchema(schema);
    expect(withRootOrgName(specialCharacters2)).not.toMatchSchema(schema);
  });

  it('should validate root org MSP name', () => {
    const withRootOrgMSPName = (n) => updatedBase((json) => {
      json.rootOrg.organization.mspName = n;
    });

    expect(withRootOrgMSPName(lettersOnly)).toMatchSchema(schema);
    expect(withRootOrgMSPName(lettersAndNumber)).toMatchSchema(schema);
    expect(withRootOrgMSPName(uppercase)).toMatchSchema(schema);
    expect(withRootOrgMSPName(domain)).not.toMatchSchema(schema);
    expect(withRootOrgMSPName(spaces)).not.toMatchSchema(schema);
    expect(withRootOrgMSPName(specialCharacters1)).not.toMatchSchema(schema);
    expect(withRootOrgMSPName(specialCharacters2)).not.toMatchSchema(schema);
  });

  it('should validate root org domain', () => {
    const withRootOrgDomain = (d) => updatedBase((json) => {
      json.rootOrg.organization.domain = d;
    });

    expect(withRootOrgDomain(lettersOnly)).toMatchSchema(schema);
    expect(withRootOrgDomain(lettersAndNumber)).toMatchSchema(schema);
    expect(withRootOrgDomain(uppercase)).not.toMatchSchema(schema);
    expect(withRootOrgDomain(domain)).toMatchSchema(schema);
    expect(withRootOrgDomain(spaces)).not.toMatchSchema(schema);
    expect(withRootOrgDomain(specialCharacters1)).not.toMatchSchema(schema);
    expect(withRootOrgDomain(specialCharacters2)).not.toMatchSchema(schema);
  });

  it('should validate root CA domain prefix', () => {
    const withRootCADomainPrefix = (d) => updatedBase((json) => {
      json.rootOrg.ca.prefix = d;
    });

    expect(withRootCADomainPrefix(lettersOnly)).toMatchSchema(schema);
    expect(withRootCADomainPrefix(lettersAndNumber)).toMatchSchema(schema);
    expect(withRootCADomainPrefix(uppercase)).not.toMatchSchema(schema);
    expect(withRootCADomainPrefix(domain)).toMatchSchema(schema);
    expect(withRootCADomainPrefix(spaces)).not.toMatchSchema(schema);
    expect(withRootCADomainPrefix(specialCharacters1)).not.toMatchSchema(schema);
    expect(withRootCADomainPrefix(specialCharacters2)).not.toMatchSchema(schema);
  });

  it('should validate root orderer domain prefix', () => {
    const withRootOrdererDomainPrefix = (d) => updatedBase((json) => {
      json.rootOrg.orderer.prefix = d;
    });

    expect(withRootOrdererDomainPrefix(lettersOnly)).toMatchSchema(schema);
    expect(withRootOrdererDomainPrefix(lettersAndNumber)).toMatchSchema(schema);
    expect(withRootOrdererDomainPrefix(uppercase)).not.toMatchSchema(schema);
    expect(withRootOrdererDomainPrefix(domain)).toMatchSchema(schema);
    expect(withRootOrdererDomainPrefix(spaces)).not.toMatchSchema(schema);
    expect(withRootOrdererDomainPrefix(specialCharacters1)).not.toMatchSchema(schema);
    expect(withRootOrdererDomainPrefix(specialCharacters2)).not.toMatchSchema(schema);
  });

  it('should validate root orderer consensus type ', () => {
    const withRootOrdererConsensus = (c) => updatedBase((json) => {
      json.rootOrg.orderer.consensus = c;
    });

    expect(withRootOrdererConsensus('solo')).toMatchSchema(schema);
    expect(withRootOrdererConsensus('raft')).toMatchSchema(schema);
    expect(withRootOrdererConsensus('kafka')).not.toMatchSchema(schema);
    expect(withRootOrdererConsensus(lettersOnly)).not.toMatchSchema(schema);
  });

  it('should validate root orderer number of instances', () => {
    const withRootOrdererNoOfInstances = (i) => updatedBase((json) => {
      json.rootOrg.orderer.instances = i;
    });

    expect(withRootOrdererNoOfInstances(1)).toMatchSchema(schema);
    expect(withRootOrdererNoOfInstances(10)).toMatchSchema(schema);
    expect(withRootOrdererNoOfInstances(0)).not.toMatchSchema(schema);
    expect(withRootOrdererNoOfInstances(11)).not.toMatchSchema(schema);
  });

  it('should validate org name', () => {
    const withOrgName = (n) => updatedBase((json) => {
      json.orgs[0].organization.name = n;
    });

    expect(withOrgName(lettersOnly)).toMatchSchema(schema);
    expect(withOrgName(lettersAndNumber)).toMatchSchema(schema);
    expect(withOrgName(uppercase)).toMatchSchema(schema);
    expect(withOrgName(domain)).not.toMatchSchema(schema);
    expect(withOrgName(spaces)).not.toMatchSchema(schema);
    expect(withOrgName(specialCharacters1)).not.toMatchSchema(schema);
    expect(withOrgName(specialCharacters2)).not.toMatchSchema(schema);
  });

  it('should validate org MSP name', () => {
    const withOrgMSPName = (n) => updatedBase((json) => {
      json.orgs[0].organization.mspName = n;
    });

    expect(withOrgMSPName(lettersOnly)).toMatchSchema(schema);
    expect(withOrgMSPName(lettersAndNumber)).toMatchSchema(schema);
    expect(withOrgMSPName(uppercase)).toMatchSchema(schema);
    expect(withOrgMSPName(domain)).not.toMatchSchema(schema);
    expect(withOrgMSPName(spaces)).not.toMatchSchema(schema);
    expect(withOrgMSPName(specialCharacters1)).not.toMatchSchema(schema);
    expect(withOrgMSPName(specialCharacters2)).not.toMatchSchema(schema);
  });

  it('should validate org domain', () => {
    const withOrgDomain = (d) => updatedBase((json) => {
      json.orgs[0].organization.domain = d;
    });

    expect(withOrgDomain(lettersOnly)).toMatchSchema(schema);
    expect(withOrgDomain(lettersAndNumber)).toMatchSchema(schema);
    expect(withOrgDomain(uppercase)).not.toMatchSchema(schema);
    expect(withOrgDomain(domain)).toMatchSchema(schema);
    expect(withOrgDomain(spaces)).not.toMatchSchema(schema);
    expect(withOrgDomain(specialCharacters1)).not.toMatchSchema(schema);
    expect(withOrgDomain(specialCharacters2)).not.toMatchSchema(schema);
  });

  it('should validate ca domain prefix', () => {
    const withCADomainPrefix = (d) => updatedBase((json) => {
      json.orgs[0].ca.prefix = d;
    });

    expect(withCADomainPrefix(lettersOnly)).toMatchSchema(schema);
    expect(withCADomainPrefix(lettersAndNumber)).toMatchSchema(schema);
    expect(withCADomainPrefix(uppercase)).not.toMatchSchema(schema);
    expect(withCADomainPrefix(domain)).toMatchSchema(schema);
    expect(withCADomainPrefix(spaces)).not.toMatchSchema(schema);
    expect(withCADomainPrefix(specialCharacters1)).not.toMatchSchema(schema);
    expect(withCADomainPrefix(specialCharacters2)).not.toMatchSchema(schema);
  });

  it('should validate peer domain prefix', () => {
    const withPeerDomainPrefix = (d) => updatedBase((json) => {
      json.orgs[0].peer.prefix = d;
    });

    expect(withPeerDomainPrefix(lettersOnly)).toMatchSchema(schema);
    expect(withPeerDomainPrefix(lettersAndNumber)).toMatchSchema(schema);
    expect(withPeerDomainPrefix(uppercase)).not.toMatchSchema(schema);
    expect(withPeerDomainPrefix(domain)).toMatchSchema(schema);
    expect(withPeerDomainPrefix(spaces)).not.toMatchSchema(schema);
    expect(withPeerDomainPrefix(specialCharacters1)).not.toMatchSchema(schema);
    expect(withPeerDomainPrefix(specialCharacters2)).not.toMatchSchema(schema);
  });

  it('should validate peer number of instances', () => {
    const withPeerNoOfInstances = (i) => updatedBase((json) => {
      json.orgs[0].peer.instances = i;
    });

    expect(withPeerNoOfInstances(1)).toMatchSchema(schema);
    expect(withPeerNoOfInstances(100)).toMatchSchema(schema);
    expect(withPeerNoOfInstances(0)).not.toMatchSchema(schema);
    expect(withPeerNoOfInstances(101)).not.toMatchSchema(schema);
  });

  it('should validate peer database type', () => {
    const withPeerDatabaseType = (db) => updatedBase((json) => {
      json.orgs[0].peer.db = db;
    });

    expect(withPeerDatabaseType('LevelDb')).toMatchSchema(schema);
    expect(withPeerDatabaseType('CouchDb')).toMatchSchema(schema);
    expect(withPeerDatabaseType('MongoDb')).not.toMatchSchema(schema);
  });

  it('should validate channel name - no spaces and capital letters', () => {
    const withChannelName = (n) => updatedBase((json) => {
      json.channels[0].name = n;
    });

    expect(withChannelName(lettersOnly)).toMatchSchema(schema);
    expect(withChannelName(lettersAndNumber)).toMatchSchema(schema);
    expect(withChannelName(uppercase)).not.toMatchSchema(schema); // no uppercase in channel name
    expect(withChannelName(domain)).not.toMatchSchema(schema);
    expect(withChannelName(spaces)).not.toMatchSchema(schema);
    expect(withChannelName(specialCharacters1)).not.toMatchSchema(schema);
    expect(withChannelName(specialCharacters2)).not.toMatchSchema(schema);
  });

  it('should validate chaincode name', () => {
    const withChaincodeName = (n) => updatedBase((json) => {
      json.chaincodes[0].name = n;
    });

    expect(withChaincodeName(lettersOnly)).toMatchSchema(schema);
    expect(withChaincodeName(lettersAndNumber)).toMatchSchema(schema);
    expect(withChaincodeName(uppercase)).toMatchSchema(schema);
    expect(withChaincodeName(domain)).not.toMatchSchema(schema);
    expect(withChaincodeName(spaces)).not.toMatchSchema(schema);
    expect(withChaincodeName(specialCharacters1)).not.toMatchSchema(schema);
    expect(withChaincodeName(specialCharacters2)).not.toMatchSchema(schema);
  });

  it('should validate chaincode version', () => {
    const withChaincodeVersion = (n) => updatedBase((json) => {
      json.chaincodes[0].version = n;
    });

    expect(withChaincodeVersion(lettersOnly)).toMatchSchema(schema);
    expect(withChaincodeVersion(lettersAndNumber)).toMatchSchema(schema);
    expect(withChaincodeVersion(uppercase)).toMatchSchema(schema);
    expect(withChaincodeVersion(domain)).toMatchSchema(schema);
    expect(withChaincodeVersion(spaces)).not.toMatchSchema(schema);
    expect(withChaincodeVersion(specialCharacters1)).not.toMatchSchema(schema);
    expect(withChaincodeVersion(specialCharacters2)).not.toMatchSchema(schema);
  });

  it('should validate chaincode language', () => {
    const withChaincodeLanguage = (l) => updatedBase((json) => {
      json.chaincodes[0].lang = l;
    });

    expect(withChaincodeLanguage('java')).toMatchSchema(schema);
    expect(withChaincodeLanguage('javascript')).toMatchSchema(schema);
    expect(withChaincodeLanguage('golang')).toMatchSchema(schema);
    expect(withChaincodeLanguage('cobol')).not.toMatchSchema(schema);
  });

  it('should validate chaincode initialization arguments', () => {
    const withChaincodeInitialization = (i) => updatedBase((json) => {
      json.chaincodes[0].init = i;
    });

    expect(withChaincodeInitialization(lettersOnly)).toMatchSchema(schema);
    expect(withChaincodeInitialization(lettersAndNumber)).toMatchSchema(schema);
    expect(withChaincodeInitialization(uppercase)).toMatchSchema(schema);
    expect(withChaincodeInitialization(domain)).toMatchSchema(schema);
    expect(withChaincodeInitialization(spaces)).toMatchSchema(schema);
    expect(withChaincodeInitialization(specialCharacters1)).toMatchSchema(schema);
    expect(withChaincodeInitialization(specialCharacters2)).toMatchSchema(schema);
  });

  it('should validate chaincode endorsement configuration', () => {
    const withChaincodeName = (n) => updatedBase((json) => {
      json.chaincodes[0].endorsement = n;
    });

    expect(withChaincodeName(lettersOnly)).toMatchSchema(schema);
    expect(withChaincodeName(lettersAndNumber)).toMatchSchema(schema);
    expect(withChaincodeName(uppercase)).toMatchSchema(schema);
    expect(withChaincodeName(domain)).toMatchSchema(schema);
    expect(withChaincodeName(spaces)).toMatchSchema(schema);
    expect(withChaincodeName(specialCharacters1)).toMatchSchema(schema);
    expect(withChaincodeName(specialCharacters2)).toMatchSchema(schema);
  });

  it('should validate chaincode directory', () => {
    const withChaincodeName = (n) => updatedBase((json) => {
      json.chaincodes[0].directory = n;
    });

    expect(withChaincodeName(lettersOnly)).toMatchSchema(schema);
    expect(withChaincodeName(lettersAndNumber)).toMatchSchema(schema);
    expect(withChaincodeName(uppercase)).toMatchSchema(schema);
    expect(withChaincodeName(domain)).toMatchSchema(schema);
    expect(withChaincodeName(spaces)).toMatchSchema(schema);
    expect(withChaincodeName(specialCharacters1)).toMatchSchema(schema);
    expect(withChaincodeName(specialCharacters2)).toMatchSchema(schema);
  });

  it('should validate chaincode private data', () => {
    const withNoPrivateData = () => updatedBase((json) => {
      const { privateData, ...rest } = json.chaincodes[0];
      json.chaincodes[0] = rest;
    });
    const withPrivateData = (d) => updatedBase((json) => {
      json.chaincodes[0].privateData = d;
    });
    const privateData = (name, ...orgNames) => ({ name, orgNames });
    const validOrgName = base.orgs[0].organization.name;
    const withPrivateDataName = (name) => withPrivateData([privateData(name, validOrgName)]);

    // various names
    expect(withPrivateDataName(lettersOnly)).toMatchSchema(schema);
    expect(withPrivateDataName(underscore)).toMatchSchema(schema);
    expect(withPrivateDataName(lettersAndNumber)).toMatchSchema(schema);
    expect(withPrivateDataName(uppercase)).toMatchSchema(schema);
    expect(withPrivateDataName(domain)).not.toMatchSchema(schema);
    expect(withPrivateDataName(spaces)).not.toMatchSchema(schema);
    expect(withPrivateDataName(specialCharacters1)).not.toMatchSchema(schema);
    expect(withPrivateDataName(specialCharacters2)).not.toMatchSchema(schema);

    // no private data, wrong object, two objects
    expect(withNoPrivateData()).toMatchSchema(schema);
    expect(withPrivateData({ wrong: 'obj' })).not.toMatchSchema(schema);
    expect(withPrivateData([
      privateData(lettersAndNumber, validOrgName),
      privateData(lettersOnly, validOrgName),
    ])).toMatchSchema(schema);
  });
});
