/* eslint no-underscore-dangle: 0 */

/*
* License-Identifier: Apache-2.0
*/
const Generator = require('yeoman-generator');
const utils = require('../utils/utils');

const configTransformers = require('../setup-docker/configTransformers');

const ValidateGeneratorType = require.resolve('../validate');

module.exports = class extends Generator {
  constructor(args, opts) {
    super(args, opts);
    this.argument('fabricaConfig', {
      type: String,
      required: true,
      description: 'fabrica config file path',
    });

    this.composeWith(ValidateGeneratorType, { arguments: [this.options.fabricaConfig] });
  }

  async writing() {
    this.options.fabricaConfigPath = utils.getFullPathOf(
      this.options.fabricaConfig, this.env.cwd,
    );

    const fabricaConfig = this.fs.readJSON(this.options.fabricaConfigPath);
    const transformedConfig = configTransformers.transformFabricaConfig(fabricaConfig);

    this.log(JSON.stringify(transformedConfig, null, 4));
  }
};
