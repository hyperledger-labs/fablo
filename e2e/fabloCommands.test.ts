import TestCommands from "./TestCommands";
import { version as currentFabloVersion } from "../package.json";
import { FabloConfigJson } from "../src/types/FabloConfigJson";
import * as fs from "fs";

const commands = new TestCommands("e2e/__tmp__/commands-tests");

describe("init", () => {
  beforeEach(() => commands.cleanupWorkdir());

  it("should init simple fablo config", () => {
    // When
    const commandResult = commands.fabloExec("init");

    // Then
    expect(commandResult).toEqual(TestCommands.success());
    expect(commandResult.output).toContain("Sample config file created! :)");
    expect(commands.getFiles()).toEqual(["e2e/__tmp__/commands-tests/fablo-config.json"]);
    expect(commands.getFileContent("fablo-config.json")).toMatchSnapshot();
  });

  it("should init simple fablo config with node chaincode", () => {
    // When
    const commandResult = commands.fabloExec("init node");

    // Then
    expect(commandResult).toEqual(TestCommands.success());
    expect(commandResult.output).toContain("Sample config file created! :)");
    expect(commands.getFiles()).toEqual([
      "e2e/__tmp__/commands-tests/chaincodes/chaincode-kv-node/.nvmrc",
      "e2e/__tmp__/commands-tests/chaincodes/chaincode-kv-node/Dockerfile",
      "e2e/__tmp__/commands-tests/chaincodes/chaincode-kv-node/index.js",
      "e2e/__tmp__/commands-tests/chaincodes/chaincode-kv-node/package-lock.json",
      "e2e/__tmp__/commands-tests/chaincodes/chaincode-kv-node/package.json",
      "e2e/__tmp__/commands-tests/fablo-config.json",
    ]);
    expect(commands.getFileContent("fablo-config.json")).toMatchSnapshot();
  });

  it("should init simple fablo config with node chaincode and rest api", () => {
    // When
    const commandResult = commands.fabloExec("init node rest");

    // Then
    expect(commandResult).toEqual(TestCommands.success());
    expect(commandResult.output).toContain("Sample config file created! :)");
    expect(commands.getFiles()).toEqual([
      "e2e/__tmp__/commands-tests/chaincodes/chaincode-kv-node/.nvmrc",
      "e2e/__tmp__/commands-tests/chaincodes/chaincode-kv-node/Dockerfile",
      "e2e/__tmp__/commands-tests/chaincodes/chaincode-kv-node/index.js",
      "e2e/__tmp__/commands-tests/chaincodes/chaincode-kv-node/package-lock.json",
      "e2e/__tmp__/commands-tests/chaincodes/chaincode-kv-node/package.json",
      "e2e/__tmp__/commands-tests/fablo-config.json",
    ]);
    expect(commands.getFileContent("fablo-config.json")).toMatchSnapshot();
  });
});

describe("use", () => {
  beforeEach(() => commands.cleanupWorkdir());

  it.skip("should display versions", () => {
    // When
    const commandResult = commands.fabloExec("use");

    // Then
    expect(commandResult).toEqual(TestCommands.success());
    expect(commands.getFiles()).toEqual([]);
  });
});

describe("validate", () => {
  beforeEach(() => commands.cleanupWorkdir());

  it("should validate default config", () => {
    // Given
    commands.fabloExec("init");

    // When
    const commandResult = commands.fabloExec("validate");

    // Then
    expect(commandResult).toEqual(TestCommands.success());
    expect(commandResult.output).toContain("Validation errors count: 0");
    expect(commandResult.output).toContain("Validation warnings count: 0");
    expect(commands.getFiles()).toContain("e2e/__tmp__/commands-tests/fablo-config.json");
  });

  it("should validate custom config", () => {
    // Given
    const fabloConfig = `${commands.relativeRoot}/samples/fablo-config-hlf2-1org-1chaincode-raft-explorer.json`;

    // When
    const commandResult = commands.fabloExec(`validate ${fabloConfig}`);

    // Then
    expect(commandResult).toEqual(TestCommands.success());
    expect(commandResult.output).toContain("Validation errors count: 0");
    expect(commandResult.output).toContain("Validation warnings count: 1");
    expect(commands.getFiles()).toEqual([]);
  });

  it("should fail to validate if config file is missing", () => {
    const commandResult = commands.fabloExec("validate");

    // Then
    expect(commandResult).toEqual(TestCommands.failure());
    expect(commandResult.output).toContain("commands-tests/fablo-config.json does not exist\n");
    expect(commands.getFiles()).toEqual([]);
  });

  it("should print validation errors", () => {
    // Given
    const sourceConfigPath = require.resolve("../samples/fablo-config-hlf2-1org-1chaincode-raft-explorer.json");
    const samplesDir = sourceConfigPath.replace("/fablo-config-hlf2-1org-1chaincode-raft-explorer.json", "");
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const sourceConfig = require(sourceConfigPath) as FabloConfigJson;

    // old schema
    sourceConfig.$schema = "https://github.com/hyperledger-labs/fablo/releases/download/1.2.0/schema.json";

    // invalid org
    sourceConfig.orgs[0].organization.mspName = "some-org1";
    sourceConfig.orgs[0].organization.name = "some-org1";

    // save updated config
    fs.writeFileSync(`${samplesDir}/invalid-fablo-config.json`, JSON.stringify(sourceConfig, null, 2));
    const fabloConfig = `${commands.relativeRoot}/samples/invalid-fablo-config.json`;

    // When
    const commandResult = commands.fabloExec(`validate ${fabloConfig}`);

    // Then
    expect(commandResult).toEqual(TestCommands.success());
    expect(commandResult.output).toContain("Critical error occured");
    expect(commandResult.output).toContain("Json schema validation failed!");
    expect(commandResult.output).toContain("instance.$schema : does not exactly match expected constant");
    expect(commandResult.output).toContain(" instance.orgs[0].organization.name : does not match pattern");
    expect(commandResult.output).toContain(" instance.orgs[0].organization.mspName : does not match pattern");
    expect(commands.getFiles()).toEqual([]);
  });
});

describe("extend config", () => {
  beforeEach(() => commands.cleanupWorkdir());

  it("should extend default config", () => {
    // Given
    commands.fabloExec("init");

    // When
    const commandResult = commands.fabloExec("extend-config", true);

    // Then
    expect(commandResult).toEqual(TestCommands.success());

    const cleanedOutput = commandResult.output
      .replace(/"fabloConfig": "(.*?)"/g, '"fabloConfig": "<absolute path>"')
      .replace(/"chaincodesBaseDir": "(.*?)"/g, '"chaincodesBaseDir": "<absolute path>"');
    expect(cleanedOutput).toMatchSnapshot();
  });

  it("should extend custom config", () => {
    // Given
    const fabloConfig = `${commands.relativeRoot}/samples/fablo-config-hlf2-2orgs-2chaincodes-raft.yaml`;

    // When
    const commandResult = commands.fabloExec(`extend-config ${fabloConfig}`, true);

    // Then
    expect(commandResult).toEqual(TestCommands.success());
    const cleanedOutput = commandResult.output
      .replace(/"fabloConfig": "(.*?)"/g, '"fabloConfig": "<absolute path>"')
      .replace(/"chaincodesBaseDir": "(.*?)"/g, '"chaincodesBaseDir": "<absolute path>"');
    expect(cleanedOutput).toMatchSnapshot();
  });

  it("should fail to extend if config file is missing", () => {
    const commandResult = commands.fabloExec("extend-config", true);

    // Then
    expect(commandResult).toEqual(TestCommands.failure());
    expect(commandResult.output).toContain("commands-tests/fablo-config.json does not exist\n");
  });
});

describe("version", () => {
  it("should print version information", () => {
    // When
    const commandResult = commands.fabloExec("version");

    // Then
    expect(commandResult).toEqual(TestCommands.success());
    expect(commandResult.outputJson()).toEqual(
      expect.objectContaining({
        version: currentFabloVersion,
        build: expect.stringMatching(/.*/),
      }),
    );
  });

  it("should print verbose version information", () => {
    // When
    const commandResult1 = commands.fabloExec("version -v");
    const commandResult2 = commands.fabloExec("version --verbose");

    // Then
    expect(commandResult1).toEqual(TestCommands.success());
    expect(commandResult1.outputJson()).toEqual(
      expect.objectContaining({
        version: currentFabloVersion,
        build: expect.stringMatching(/.*/),
        supported: expect.objectContaining({
          fabloVersions: expect.stringMatching(/.*/),
        }),
      }),
    );

    expect(commandResult1.status).toEqual(commandResult2.status);
    expect(commandResult1.output).toEqual(commandResult2.output);
  });
});
