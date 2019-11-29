'use strict';

const Generator = require('yeoman-generator');

module.exports = class extends Generator {

  async configuring() {
    await this.config.save(); // TODO how to remove the initial file??

    const OrgGenerator = require.resolve('../create-org');
    const CAGenerator = require.resolve('../create-ca');
    const OrdererGenerator = require.resolve('../create-orderer');
    const PeerGenerator = require.resolve('../create-peer');

    this
      .composeWith(OrgGenerator, {orgNamespace: 'root'})
      .composeWith(CAGenerator, {orgNamespace: 'root'})
      .composeWith(OrdererGenerator, {orgNamespace: 'root'})
      .composeWith(OrgGenerator, {orgNamespace: 'org1'})
      .composeWith(CAGenerator, {orgNamespace: 'org1'})
      .composeWith(PeerGenerator, {orgNamespace: 'org1'});
  }

};
