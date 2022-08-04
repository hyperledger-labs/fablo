import * as Generator from "yeoman-generator";
import parseFabloConfig from "../utils/parseFabloConfig";

const DockerGeneratorPath = require.resolve("../setup-docker");
const KubernetesGeneratorPath = require.resolve("../setup-k8s");

export default class SetupDockerGenerator extends Generator {
  constructor(args: string[], opts: Generator.GeneratorOptions) {
    super(args, opts);
    this.argument("fabloConfig", {
      type: String,
      optional: true,
      description: "Fablo config file path",
      default: "../../network/fablo-config.json",
    });
  }

  redirectToProperGenerator() {
    const fabloConfigPath = `${this.env.cwd}/${this.options.fabloConfig}`;
    const json = parseFabloConfig(this.fs.read(fabloConfigPath));

    if (json?.global?.engine === "kubernetes") {
      this.composeWith(KubernetesGeneratorPath);
    } else {
      this.composeWith(DockerGeneratorPath);
    }
  }
}
