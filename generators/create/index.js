'use strict';

const Generator = require('yeoman-generator');

module.exports = class extends Generator {

  async prompting() {
    // const questions = [{
    //   type: 'list',
    //   name: 'subgenerator',
    //   message: 'Select asset to create',
    //   choices: [
    //     {name: 'Network', value: 'create-network'},
    //     {name: 'Organisation', value: 'create-organisation'},
    //     {name: 'Peer', value: 'create-peer'}
    //   ]
    // }];
    // const answers = await this.prompt(questions);
    // Object.assign(this.options, answers);

  }

  async configuring() {
    await this.config.save();

    const OrgGenerator = require.resolve('../create-org');
    const CAGenerator = require.resolve('../create-ca');
    const OrdererGenerator = require.resolve('../create-orderer');
    const PeerGenerator = require.resolve('../create-peer');

    this
      .composeWith(OrgGenerator, {isRoot: true})
      .composeWith(CAGenerator, {isRoot: true})
      .composeWith(OrdererGenerator, {isRoot: true})
      .composeWith(OrgGenerator)
      .composeWith(CAGenerator)
      .composeWith(PeerGenerator);
  }

};
