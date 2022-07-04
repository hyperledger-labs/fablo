import * as Generator from "yeoman-generator";

export default class extends Generator {
  displayInfo(): void {
    const url = "https://github.com/hyperledger-labs/fablo";
    this.log("This is main entry point for Yeoman app used in Fablo.");
    this.log("Visit the project page to get more information.");
    this.log(`---\n${url}\n---`);
  }
}
