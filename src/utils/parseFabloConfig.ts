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
      const jsonError = e instanceof Error ? e.message : String(e);
      const yamlError = e2 instanceof Error ? e2.message : String(e2);
      throw new Error(
        `Cannot parse config file.\n  JSON error: ${jsonError}\n  YAML error: ${yamlError}`,
      );
    }
  }
};

export default parseFabloConfig;
