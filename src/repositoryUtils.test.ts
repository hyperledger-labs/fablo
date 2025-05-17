import { sortVersions, version } from "./repositoryUtils";

describe("repositoryUtils", () => {

  it("should sort versions", () => {
    const unsorted = [
      "0.0.2",
      "0.0.2-unstable",
      "0.0.1",
      "0.1.11",
      "0.1.1",
      "0.1.1-unstable",
      "1.21.2",
    ];

    const expected = [
      "1.21.2",
      "0.1.11",
      "0.1.1",
      "0.0.2",
      "0.0.1",
      "0.1.1-unstable",
      "0.0.2-unstable",
    ];

    expect(sortVersions(unsorted)).toEqual(expected);
  });

  it("should place pre‑release (named) tags after the matching stable tag", () => {
    const unsorted = [
      "0.1.1-alpha",
      "0.1.1-beta",
      "0.1.2-alpha",
      "0.1.2",
      "0.1.1",
    ];

    const expected = [
      "0.1.2",
      "0.1.1",
      "0.1.2-alpha",
      "0.1.1-beta",
      "0.1.1-alpha",
    ];

    expect(sortVersions(unsorted)).toEqual(expected);
  });

  it("should handle multi digit fragments correctly", () => {
    const unsorted = ["1.9.9", "1.10.0", "1.9.10"];
    const expected = ["1.10.0", "1.9.10", "1.9.9"];
    expect(sortVersions(unsorted)).toEqual(expected);
  });


  it("should compare versions", () => {
    expect(version("1.4.0").isGreaterOrEqual("1.4.0")).toBe(true);
    expect(version("1.4.0").isGreaterOrEqual("1.4.1")).toBe(false);
    expect(version("1.4.0").isGreaterOrEqual("1.3.0")).toBe(true);
    expect(version("1.4.0").isGreaterOrEqual("2.1.0")).toBe(false);
    expect(version("3.0.0").isGreaterOrEqual("3.0.0-beta")).toBe(true);
    expect(version("3.0.0-beta").isGreaterOrEqual("3.0.0")).toBe(true);
    expect(version("3.0.0").isGreaterOrEqual("3.0.0")).toBe(true);
    expect(version("3.0.0").isGreaterOrEqual("3.0.1")).toBe(false);
  });

  it("should treat pre-release tags as equal to the corresponding stable tag for ≥ comparison", () => {
    expect(version("0.0.1-alpha").isGreaterOrEqual("0.0.1")).toBe(true);
    expect(version("0.0.1").isGreaterOrEqual("0.0.1-alpha")).toBe(true);
  });


  it("should check membership with isOneOf()", () => {
    const list = ["1.2.3", "2.0.0", "3.1.4-alpha"];
    expect(version("1.2.3").isOneOf(list)).toBe(true);
    expect(version("3.1.4").isOneOf(list)).toBe(false);
  });


  it("should take major.minor fragments only", () => {
    expect(version("10.5.7").takeMajorMinor()).toBe("10.5");
    expect(version("2.0.0-beta").takeMajorMinor()).toBe("2.0");
  });
});
