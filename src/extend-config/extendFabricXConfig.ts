import { FabricXConfig } from "../types/FabloConfigExtended";
import { FabricXJson } from "../types/FabloConfigJson";
import defaults from "./defaults";

const extendFabricXConfig = (fabricXJson: FabricXJson | undefined): FabricXConfig => ({
  orderer: {
    parties: (fabricXJson?.orderer?.parties ?? []).map(({ organization }) => ({
      organization: {
        name: organization.name,
        domain: organization.domain,
        mspName: organization.mspName ?? defaults.organization.mspName(organization.name),
      },
    })),
  },
});
export default extendFabricXConfig;

