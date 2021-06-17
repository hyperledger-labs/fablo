import TestCommands from "./TestCommands";
import { extendConfig } from "../src/extend-config";
import parseFabricaConfig from "../src/utils/parseFabricaConfig";

const commands = new TestCommands("e2e/__tmp__/extend-config-tests");

describe("extend config", () => {
  beforeEach(() => commands.cleanupWorkdir());

  beforeAll(() => {
    process.env.FABRICA_CONFIG = "<absolute path>";
    process.env.CHAINCODES_BASE_DIR = "<absolute path>";
  });

  afterAll(() => {
    delete process.env.FABRICA_CONFIG;
    delete process.env.CHAINCODES_BASE_DIR;
  });

  const files = commands.getFiles("samples/*.json").concat(commands.getFiles("samples/*.yaml"));

  files.forEach((file) => {
    it(file, () => {
      const fileContent = commands.getFileContent(`${commands.relativeRoot}/${file}`);
      const json = parseFabricaConfig(fileContent);

      // when
      const extended = extendConfig(json);

      // then
      expect(extended).toMatchSnapshot();
    });
  });
});
