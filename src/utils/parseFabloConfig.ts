import * as yaml from "js-yaml";
import { FabloConfigJson } from "../types/FabloConfigJson";

const parseFabloConfig = (str: string): FabloConfigJson => {
  try {
    return JSON.parse(str);
  } catch (e) {
    try {
      const yamlContent = yaml.load(str);
      return JSON.parse(JSON.stringify(yamlContent));
    } catch (e2) {
      throw new Error("Cannot parse file neither as JSON nor YAML file.");
    }
  }
};

export default parseFabloConfig;
