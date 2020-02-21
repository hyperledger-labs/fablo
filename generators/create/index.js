
const Generator = require('yeoman-generator');
const utils = require('../utils');

module.exports = class extends Generator {
  async configuring() {
    const onSuccess = () => {
      const OrgGenerator = require.resolve('../create-org');
      const CAGenerator = require.resolve('../create-ca');
      const OrdererGenerator = require.resolve('../create-orderer');
      const PeerGenerator = require.resolve('../create-peer');

      this
        .composeWith(OrgGenerator, { orgKey: utils.rootKey })
        .composeWith(CAGenerator, { orgKey: utils.rootKey })
        .composeWith(OrdererGenerator, { orgKey: utils.rootKey })
        .composeWith(OrgGenerator, { orgKey: 'org1' })
        .composeWith(CAGenerator, { orgKey: 'org1' })
        .composeWith(PeerGenerator, { orgKey: 'org1' });
    };

    const onFailure = () => {
      const AppStart = require.resolve('../app');
      this.composeWith(AppStart);
    };

    const DeleteConfig = require.resolve('../delete-config');
    this.composeWith(DeleteConfig, { handleDeleteConfig: { onSuccess, onFailure } });
  }
};
