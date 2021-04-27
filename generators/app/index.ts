import Generator from "yeoman-generator";
import * as config from "../config";

export default class extends Generator {
  initializing(): void {
    this.log(config.splashScreen());
  }

  displayInfo(): void {
    const url = "https://github.com/softwaremill/fabrica";
    this.log("This is main entry point for Yeoman app used in Fabrica.");
    this.log("Visit the project page to get more information.");
    this.log(`---\n${url}\n---`);
  }
}
