import got from "got";

const repositoryName = "softwaremill/fablo";
const repositoryTagsListUrl = `https://registry.hub.docker.com/v2/repositories/${repositoryName}/tags`;

const incrementVersionFragment = (versionFragment: string) => {
  if (versionFragment.includes("-")) {
    const splitted = versionFragment.split("-");
    return `${+splitted[0] + 100000}-${splitted[1]}`;
  }
  return +versionFragment + 100000;
};

const incrementVersionFragments = (v: string) => v.split(".").map(incrementVersionFragment).join(".");

const decrementVersionFragment = (incrementedVersionFragment: string) => {
  if (incrementedVersionFragment.includes("-")) {
    const splitted = incrementedVersionFragment.split("-");
    return `${+splitted[0] - 100000}-${splitted[1]}`;
  }
  return +incrementedVersionFragment - 100000;
};

const decrementVersionFragments = (v: string) => v.split(".").map(decrementVersionFragment).join(".");

const namedVersionsAsLast = (a: string, b: string) => {
  if (/[a-z]/i.test(a) && !/[a-z]/i.test(b)) return -1;
  if (/[a-z]/i.test(b) && !/[a-z]/i.test(a)) return 1;
  if (a.toString() < b.toString()) return -1;
  if (a.toString() > b.toString()) return 1;
  return 0;
};

const sortVersions = (versions: string[]): string[] =>
  versions.map(incrementVersionFragments).sort(namedVersionsAsLast).map(decrementVersionFragments).reverse();

interface Version {
  isGreaterOrEqual(v2: string): boolean;
  isOneOf(vs: string[]): boolean;
}

const version = (v: string): Version => ({
  isGreaterOrEqual(v2: string) {
    const vStd = incrementVersionFragments(v).split("-")[0];
    const v2Std = incrementVersionFragments(v2).split("-")[0];
    return vStd >= v2Std;
  },
  isOneOf(vs: string[]): boolean {
    return vs.includes(v);
  },
});

const requestVersionNames = (): Promise<{ results: { name: string }[] }> => {
  const params = {
    searchParams: {
      tag_status: "active",
      page_size: 1024,
    },
  };
  return got(repositoryTagsListUrl, params).json<{ results: { name: string }[] }>();
};

const getAvailableTags = async (): Promise<string[]> => {
  try {
    const versionNames = (await requestVersionNames()).results
      .filter((v) => v.name !== "latest")
      .map((tag) => tag.name);
    return sortVersions(versionNames);
  } catch (err) {
    console.log(`Could not check for updates. Url: '${repositoryTagsListUrl}' not available`);
    return [];
  }
};

export { getAvailableTags, sortVersions, version };
