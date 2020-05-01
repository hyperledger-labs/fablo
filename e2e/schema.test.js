/* eslint-disable no-param-reassign */

const { matchers } = require('jest-json-schema');
const schema = require('../docs/schema');
const sample01 = require('../samples/fabrikkaConfig-1org-1channel-1chaincode');
const sample02 = require('../samples/fabrikkaConfig-2orgs-2channels-1chaincode');
const docsSample = require('../docs/sample');

expect.extend(matchers);

describe('samples', () => {
  [
    ['sample01', sample01],
    ['sample02', sample02],
    ['docsSample', docsSample],
  ].forEach(([name, json]) => {
    it(`${name} should match schema`, () => {
      expect(json).toMatchSchema(schema);
    });
  });
});

describe('schema', () => {
  const base = docsSample;
  expect(base).toMatchSchema(schema);

  const updatedBase = (updateJson) => {
    const json = JSON.parse(JSON.stringify(base));
    updateJson(json);
    return json;
  };

  const lettersOnly = 'lettersonly';
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

  it('should validate root org key', () => {
    const withRootOrgKey = (k) => updatedBase((json) => {
      json.rootOrg.organization.key = k;
    });

    expect(withRootOrgKey(lettersOnly)).toMatchSchema(schema);
    expect(withRootOrgKey(lettersAndNumber)).toMatchSchema(schema);
    expect(withRootOrgKey(uppercase)).not.toMatchSchema(schema);
    expect(withRootOrgKey(domain)).not.toMatchSchema(schema);
    expect(withRootOrgKey(spaces)).not.toMatchSchema(schema);
    expect(withRootOrgKey(specialCharacters1)).not.toMatchSchema(schema);
    expect(withRootOrgKey(specialCharacters2)).not.toMatchSchema(schema);
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

  it('should validate org key', () => {
    const withOrgKey = (k) => updatedBase((json) => {
      json.orgs[0].organization.key = k;
    });

    expect(withOrgKey(lettersOnly)).toMatchSchema(schema);
    expect(withOrgKey(lettersAndNumber)).toMatchSchema(schema);
    expect(withOrgKey(uppercase)).not.toMatchSchema(schema);
    expect(withOrgKey(domain)).not.toMatchSchema(schema);
    expect(withOrgKey(spaces)).not.toMatchSchema(schema);
    expect(withOrgKey(specialCharacters1)).not.toMatchSchema(schema);
    expect(withOrgKey(specialCharacters2)).not.toMatchSchema(schema);
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

  it('should validate channel key', () => {
    const withChannelKey = (k) => updatedBase((json) => {
      json.channels[0].key = k;
    });

    expect(withChannelKey(lettersOnly)).toMatchSchema(schema);
    expect(withChannelKey(lettersAndNumber)).toMatchSchema(schema);
    expect(withChannelKey(uppercase)).not.toMatchSchema(schema);
    expect(withChannelKey(domain)).not.toMatchSchema(schema);
    expect(withChannelKey(spaces)).not.toMatchSchema(schema);
    expect(withChannelKey(specialCharacters1)).not.toMatchSchema(schema);
    expect(withChannelKey(specialCharacters2)).not.toMatchSchema(schema);
  });

  it('should validate channel name - bez spacji i wlk liter', () => {
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

  it('should validate channel ogranization key', () => {
    const withChannelOrgKey = (k) => updatedBase((json) => {
      json.channels[0].orgs[0].key = k;
    });

    expect(withChannelOrgKey(lettersOnly)).toMatchSchema(schema);
    expect(withChannelOrgKey(lettersAndNumber)).toMatchSchema(schema);
    expect(withChannelOrgKey(uppercase)).not.toMatchSchema(schema);
    expect(withChannelOrgKey(domain)).not.toMatchSchema(schema);
    expect(withChannelOrgKey(spaces)).not.toMatchSchema(schema);
    expect(withChannelOrgKey(specialCharacters1)).not.toMatchSchema(schema);
    expect(withChannelOrgKey(specialCharacters2)).not.toMatchSchema(schema);
  });

  it('should validate channel organization peer key', () => {
    const withChannelPeerKey = (k) => updatedBase((json) => {
      json.channels[0].key = k;
    });

    expect(withChannelPeerKey(lettersOnly)).toMatchSchema(schema);
    expect(withChannelPeerKey(lettersAndNumber)).toMatchSchema(schema);
    expect(withChannelPeerKey(uppercase)).not.toMatchSchema(schema);
    expect(withChannelPeerKey(domain)).not.toMatchSchema(schema);
    expect(withChannelPeerKey(spaces)).not.toMatchSchema(schema);
    expect(withChannelPeerKey(specialCharacters1)).not.toMatchSchema(schema);
    expect(withChannelPeerKey(specialCharacters2)).not.toMatchSchema(schema);
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
    expect(withChaincodeLanguage('go')).toMatchSchema(schema);
    expect(withChaincodeLanguage('cobol')).not.toMatchSchema(schema);
  });

  it('should validate chaincode channel key', () => {
    const withChaincodeChannel = (k) => updatedBase((json) => {
      json.chaincodes[0].channel = k;
    });

    expect(withChaincodeChannel(lettersOnly)).toMatchSchema(schema);
    expect(withChaincodeChannel(lettersAndNumber)).toMatchSchema(schema);
    expect(withChaincodeChannel(uppercase)).not.toMatchSchema(schema);
    expect(withChaincodeChannel(domain)).not.toMatchSchema(schema);
    expect(withChaincodeChannel(spaces)).not.toMatchSchema(schema);
    expect(withChaincodeChannel(specialCharacters1)).not.toMatchSchema(schema);
    expect(withChaincodeChannel(specialCharacters2)).not.toMatchSchema(schema);
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
});
