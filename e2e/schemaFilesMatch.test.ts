import { matchers } from "jest-json-schema";
import TestCommands from "./TestCommands";
import schema from "../docs/schema.json";

expect.extend(matchers);

const commands = new TestCommands("./e2e/__tmp__/schema-files-match-tests");

describe("schema files match", () => {
  const files = commands.getFiles("samples/*.json");

  files.forEach((file) => {
    it(file, () => {
      // eslint-disable-next-line @typescript-eslint/no-var-requires
      const json = require(`../${file}`);
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      expect(json).toMatchSchema(schema);
    });
  });
});
