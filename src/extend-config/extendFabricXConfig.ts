import { FabricXConfig } from "../types/FabloConfigExtended";
import { FabricXJson } from "../types/FabloConfigJson";
import defaults from "./defaults";

const extendFabricXConfig = (fabricXJson: FabricXJson | undefined): FabricXConfig => {
  const partyCount = fabricXJson?.orderer?.partyCount ?? defaults.fabricX.orderer.partyCount;
  return {
    orderer: {
      parties: Array.from({ length: partyCount }, (_, i) => ({
        organization: defaults.fabricX.orderer.organization(i + 1, partyCount),
      })),
    },
  };
};
export default extendFabricXConfig;
