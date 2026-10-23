import { buildFabricXOrderer } from "./fabricXOrderer";

describe("buildFabricXOrderer", () => {
  const orderer = buildFabricXOrderer(1);
  const [party] = orderer.parties;

  it("describes the single party with the names the generator always used", () => {
    expect(orderer.parties).toHaveLength(1);
    expect(party.partyId).toBe(1);
    expect(party.slug).toBe("party1");
    expect(party.endpointId).toBe(0);
    expect(party.org).toEqual({ name: "Orderer", domain: "orderer.example.com", mspId: "OrdererOrdererMSP" });
    expect(orderer.faultTolerance).toBe("CFT");
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

  it("rejects party counts the generator cannot render", () => {
    [0, 2, 3, 5].forEach((count) => expect(() => buildFabricXOrderer(count)).toThrow(/supports 1 or 4 parties/));
  });

  describe("four party profile", () => {
    const four = buildFabricXOrderer(4);

    it("uses BFT and gives every party its own org", () => {
      expect(four.faultTolerance).toBe("BFT");
      expect(four.parties.map((p) => p.org.mspId)).toEqual([
        "OrdererOrg1MSP",
        "OrdererOrg2MSP",
        "OrdererOrg3MSP",
        "OrdererOrg4MSP",
      ]);
      expect(four.parties.map((p) => p.org.domain)).toEqual([
        "orderer-org-1",
        "orderer-org-2",
        "orderer-org-3",
        "orderer-org-4",
      ]);
      expect(four.parties.map((p) => p.endpointId)).toEqual([0, 1, 2, 3]);
    });

    it("adds the party number to host names and moves ports by 100 per party", () => {
      expect(four.parties.map((p) => p.router.host)).toEqual([
        "orderer-party1-router",
        "orderer-party2-router",
        "orderer-party3-router",
        "orderer-party4-router",
      ]);
      expect(four.parties.map((p) => p.router.port)).toEqual([7050, 7150, 7250, 7350]);
      expect(four.parties[3].assembler.port).toBe(7353);
    });

    it("never repeats a host name, port, data folder or config file", () => {
      const nodes = four.parties.flatMap((p) => [p.router, ...p.batchers, p.consenter, p.assembler]);
      ["host", "port", "dataDir", "configFile"].forEach((key) => {
        const values = nodes.map((n) => n[key as keyof typeof n]);
        expect(new Set(values).size).toBe(nodes.length);
      });
    });

    it("puts the node certificates in the folder of the org of the party", () => {
      expect(four.parties[1].consenter.cryptoDir).toBe(
        "ordererOrganizations/orderer-org-2/orderers/party2/consenter.orderer-org-2",
      );
    });
  });
});
