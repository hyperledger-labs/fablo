import { HooksJson } from "../types/FabloConfigJson";
import { HooksConfig } from "../types/FabloConfigExtended";

const extendHooksConfig = (hooksJson: HooksJson | undefined): HooksConfig => {
  const postGenerate = typeof hooksJson?.postGenerate === "string" ? hooksJson.postGenerate : "";
  const postStart = typeof hooksJson?.postStart === "string" ? hooksJson.postStart : "";
  return {
    postGenerate,
    postStart,
  };
};
export default extendHooksConfig;
