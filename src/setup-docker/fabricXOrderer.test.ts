import { buildFabricXOrderer, SUPPORTED_ORDERER_PARTIES } from "./fabricXOrderer";

describe("buildFabricXOrderer", () => {
  const orderer = buildFabricXOrderer(1);
  const [party] = orderer.parties;

  it("describes the single party with the names the generator always used", () => {
    expect(orderer.parties).toHaveLength(1);
    expect(party.partyId).toBe(1);
    expect(party.slug).toBe("party1");
    expect(party.endpointId).toBe(0);
    expect(orderer.org).toEqual({ name: "Orderer", domain: "orderer.example.com", mspId: "OrdererOrdererMSP" });
  });

  it("keeps host names and ports of the single party", () => {
    expect([party.router.host, party.router.port]).toEqual(["orderer-router", 7050]);
    expect([party.batchers[0].host, party.batchers[0].port]).toEqual(["orderer-batcher", 7051]);
    expect([party.consenter.host, party.consenter.port]).toEqual(["orderer-consenter", 7052]);
    expect([party.assembler.host, party.assembler.port]).toEqual(["orderer-assembler", 7053]);
  });

  it("keeps crypto, data and config paths of the single party", () => {
    expect(party.router.cryptoDir).toBe(
      "ordererOrganizations/orderer.example.com/orderers/party1/router.orderer.example.com",
    );
    expect(party.batchers[0].cryptoDir).toBe(
      "ordererOrganizations/orderer.example.com/orderers/party1/batcher1.orderer.example.com",
    );
    expect(party.consenter.dataDir).toBe("data/orderers/party1-consenter");
    expect(party.assembler.configFile).toBe("config/party1-assembler.yaml");
    expect(party.batchers[0].shardId).toBe(1);
  });

  it("starts the consenter with the consensus command", () => {
    expect(party.consenter.command).toBe("consensus");
    expect(party.router.command).toBe("router");
  });

  it("rejects more parties than the generator can render", () => {
    expect(() => buildFabricXOrderer(SUPPORTED_ORDERER_PARTIES + 1)).toThrow(/supports 1 party/);
    expect(() => buildFabricXOrderer(0)).toThrow(/supports 1 party/);
  });
});
