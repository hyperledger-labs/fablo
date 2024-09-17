import got from "got";

const repositoryTagsListUrl = `https://api.github.com/repos/hyperledger-labs/fablo/releases`;

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
  takeMajorMinor(): string;
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
  takeMajorMinor(): string {
    const [major, minor] = v.split(".");
    return `${major}.${minor}`;
  },
});

const requestVersionNames = (): Promise<{ tag_name: string }[]> => {
  const params = {
    searchParams: {
      tag_status: "active",
      page_size: 1024,
    },
  };
  return got(repositoryTagsListUrl, params).json<{ tag_name: string }[]>();
};

const versionRegex = /^v\d+\.\d+\.\d+(-[a-zA-Z0-9-]+)?$/;

const getAvailableTags = async (): Promise<string[]> => {
  try {
    const versionNames = (await requestVersionNames())
      .filter((release) => versionRegex.test(release.tag_name))
      .map((release) => release.tag_name.slice(1));
    return sortVersions(versionNames);
  } catch (err) {
    console.log(`Could not check for updates. Url: '${repositoryTagsListUrl}' not available`);
    return [];
  }
};

export { getAvailableTags, sortVersions, version };
