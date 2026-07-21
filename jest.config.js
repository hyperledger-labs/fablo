module.exports = {
  modulePathIgnorePatterns: [
    "<rootDir>/dist/",
    "<rootDir>/e2e/__tmp__/",
    "<rootDir>/e2e-network/.*\\.tmpdir/",
  ],
  preset: "ts-jest",
  testPathIgnorePatterns: [
    "/node_modules/",
    "/dist/",
    "/e2e/__tmp__/",
    "/e2e-network/.*\\.tmpdir/",
  ],
};
