/*
 * License-Identifier: Apache-2.0
 */

'use strict';

const Generator = require('yeoman-generator');
module.exports = class extends Generator {

    desc() {
        this.log('Imports produced config to config.json. It can be shared between organizations or developers');
    }

    splash() {
        this.log('Nothing there yet... Sorry !');
    }

};
