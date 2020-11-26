/* eslint no-underscore-dangle: 0 */

/*
* License-Identifier: Apache-2.0
*/
const Generator = require('yeoman-generator');

const {version} = require('../config');
const got = require('got');
const chalk = require('chalk');

let dockerRepositoryName = "softwaremill/fabrica"

module.exports = class extends Generator {

    async checkUpdates() {
        const allAvailableVersions = await this._getAllVersionsSorted();
        const newerVersions = this._getAllNewerVersions(version, allAvailableVersions);

        if (newerVersions.length > 0) {
            let msg = chalk.bold("There are new fabrica versions available! :)")
            this.log(msg);
            this.log(chalk.underline.bold("all")+` newer versions: ${JSON.stringify(newerVersions, null, 2)}`);
            this.log("");
            this.log("To update just run command:");
            this.log("\t"+chalk.bold("fabrica updateTo [version]"));
        } else {
            this.log(chalk.bold(`No updates available. ${version} seems to be the latest one`));
        }
    };

    async _getAllVersionsSorted() {
        let url = `https://registry.hub.docker.com/v2/repositories/${dockerRepositoryName}/tags`
        let params = {
            searchParams: {
                tag_status: 'active',
                page_size: 1024
            }
        }
        const tagsResponse = await got(url, params).json();
        return tagsResponse.results.map((result) => {
            return {
                name: result.name,
                last_pushed: result.tag_last_pushed
            }
        })
            .filter((result) => result.name !== "latest")
            .sort((a, b) => {
                return new Date(b.last_pushed) - new Date(a.last_pushed);
            })
            .map((result) => result.name)
    }

    _getAllNewerVersions(currentVersion, allVersions) {
        const currentVersionIndex = allVersions.reverse().indexOf(currentVersion);
        return allVersions.slice(currentVersionIndex+1, allVersions.length).reverse()
    }

}
