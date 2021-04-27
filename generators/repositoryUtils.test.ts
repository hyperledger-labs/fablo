import { sortVersions, version } from "./repositoryUtils";

describe("repositoryUtils", () => {
  it("should sort versions", () => {
    // Given
    const unsortedVersions = ["0.0.2", "0.0.2-unstable", "0.0.1", "0.1.11", "0.1.1", "0.1.1-unstable", "1.21.2"];

    // When
    const sortedVersions = sortVersions(unsortedVersions);

    // Then
    const expectedVersions = ["1.21.2", "0.1.11", "0.1.1", "0.0.2", "0.0.1", "0.1.1-unstable", "0.0.2-unstable"];

    expect(sortedVersions).toEqual(expectedVersions);
  });

  it("should compare versions", () => {
    expect(version("1.4.0").isGreaterOrEqual("1.4.0")).toBe(true);
    expect(version("1.4.0").isGreaterOrEqual("1.4.1")).toBe(false);
    expect(version("1.4.0").isGreaterOrEqual("1.3.0")).toBe(true);
    expect(version("1.4.0").isGreaterOrEqual("2.1.0")).toBe(false);
  });
});
