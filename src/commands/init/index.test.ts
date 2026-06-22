import { parseOverrideValue, applyOverride } from "./index";
import { FabloConfigJson } from "../../types/FabloConfigJson";

describe("Init Command Helpers", () => {
  describe("parseOverrideValue", () => {
    it("should parse booleans correctly", () => {
      expect(parseOverrideValue("true")).toBe(true);
      expect(parseOverrideValue("false")).toBe(false);
      expect(parseOverrideValue("TRUE")).toBe(true);
      expect(parseOverrideValue("FALSE")).toBe(false);
    });

    it("should parse null correctly", () => {
      expect(parseOverrideValue("null")).toBe(null);
      expect(parseOverrideValue("NULL")).toBe(null);
    });

    it("should parse strict numbers correctly", () => {
      expect(parseOverrideValue("15")).toBe(15);
      expect(parseOverrideValue("-4")).toBe(-4);
      expect(parseOverrideValue("3.14")).toBe(3.14);
      expect(parseOverrideValue("0")).toBe(0);
    });

    it("should keep string numbers with leading zeros or exponents as strings", () => {
      expect(parseOverrideValue("001")).toBe("001");
      expect(parseOverrideValue("09")).toBe("09");
      expect(parseOverrideValue("1e3")).toBe("1e3");
      expect(parseOverrideValue("0x10")).toBe("0x10");
    });

    it("should parse quoted strings as string literals", () => {
      expect(parseOverrideValue('"My Org"')).toBe("My Org");
      expect(parseOverrideValue("'My Org'")).toBe("My Org");
      expect(parseOverrideValue('"true"')).toBe("true");
      expect(parseOverrideValue('"null"')).toBe("null");
      expect(parseOverrideValue('"001"')).toBe("001");
    });

    it("should parse JSON objects and arrays correctly", () => {
      expect(parseOverrideValue("{}")).toEqual({});
      expect(parseOverrideValue("[]")).toEqual([]);
      expect(parseOverrideValue('{"a":1}')).toEqual({ a: 1 });
      expect(parseOverrideValue('["peer0","peer1"]')).toEqual(["peer0", "peer1"]);
    });

    it("should fallback to raw string for invalid JSON starting with bracket/brace", () => {
      expect(parseOverrideValue("{abc")).toBe("{abc");
    });
  });

  describe("applyOverride", () => {
    let config: FabloConfigJson;
    let logOutput: string[];
    const logger = (msg: string) => logOutput.push(msg);

    beforeEach(() => {
      config = {
        $schema: "some-schema",
        global: {
          fabricVersion: "3.1.0",
          tls: true,
          peerDevMode: false,
        },
        orgs: [],
        channels: [],
        chaincodes: [],
        hooks: {},
      };
      logOutput = [];
    });

    it("should set nested values and normalize brackets", () => {
      applyOverride(config, "global.fabricVersion", "3.2.0", logger);
      expect(config.global.fabricVersion).toBe("3.2.0");
      expect(logOutput[0]).toContain("ℹ Dynamic override: global.fabricVersion = 3.2.0");
    });

    it("should support array index modification", () => {
      config.chaincodes = [
        { name: "mycc", version: "1.0", lang: "node", channel: "mychan", directory: ".", privateData: [] },
      ];
      applyOverride(config, "chaincodes[0].name", "newname", logger);
      expect(config.chaincodes[0].name).toBe("newname");
      expect(logOutput[0]).toContain("ℹ Dynamic override: chaincodes.0.name = newname");
    });

    it("should redact sensitive overrides in logs", () => {
      applyOverride(config, "global.token", "my-secret-token", logger);
      expect((config.global as any).token).toBe("my-secret-token");
      expect(logOutput[0]).toContain("ℹ Dynamic override: global.token = ********");
      expect(logOutput[0]).not.toContain("my-secret-token");
    });
  });
});
