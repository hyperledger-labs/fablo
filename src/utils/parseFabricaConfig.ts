import * as yaml from "js-yaml";
import { FabricaConfigJson } from "../types/FabricaConfigJson";

const parseFabricaConfig = (str: string): FabricaConfigJson => {
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

export default parseFabricaConfig;
