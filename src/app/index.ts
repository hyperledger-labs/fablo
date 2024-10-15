import * as Generator from "yeoman-generator";

export default class extends Generator {
  displayInfo(): void {
    const url = "https://github.com/hyperledger-labs/fablo";
    console.log("This is main entry point for Yeoman app used in Fablo.");
    console.log("Visit the project page to get more information.");
    console.log(`---\n${url}\n---`);
  }
}
