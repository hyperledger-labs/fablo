import extendGlobal from "./extendGlobal";

describe("extendGlobal fabricImages", () => {
  const envBackup = { ...process.env };

  beforeEach(() => {
    process.env = { ...envBackup, FABLO_CONFIG: "/tmp/fablo-config.json", CHAINCODES_BASE_DIR: "/tmp/chaincodes" };
  });

  afterAll(() => {
    process.env = envBackup;
  });

  it("should use default Fabric image repositories for Fabric 2.x", () => {
    const global = extendGlobal({
      fabricVersion: "2.5.12",
      tls: true,
      peerDevMode: false,
    });

    expect(global.peerImage).toBe("hyperledger/fabric-peer:2.5.12");
    expect(global.ordererImage).toBe("hyperledger/fabric-orderer:2.5.12");
    expect(global.caImage).toBe("hyperledger/fabric-ca:1.5.16");
    expect(global.toolsImage).toBe("hyperledger/fabric-tools:2.5.12");
    expect(global.ccenvImage).toBe("hyperledger/fabric-ccenv:2.5.12");
    expect(global.baseosImage).toBe("hyperledger/fabric-baseos:2.5.12");
    expect(global.javaenvImage).toBe("hyperledger/fabric-javaenv:2.5");
    expect(global.nodeenvImage).toBe("hyperledger/fabric-nodeenv:2.5");
  });

  it("should use ghcr tools image by default for Fabric 3.x", () => {
    const global = extendGlobal({
      fabricVersion: "3.1.0",
      tls: true,
      peerDevMode: false,
    });

    expect(global.toolsImage).toBe("ghcr.io/fablo-io/fabric-tools:3.1.3");
  });

  it("should append default tags when overriding image repositories without tags", () => {
    const global = extendGlobal({
      fabricVersion: "3.1.0",
      tls: true,
      peerDevMode: false,
      fabricImages: {
        peer: "fablo.io/peer/fabric-peer",
        tools: "fablo.io/tools/fabric-tools",
        nodeenv: "fablo.io/nodeenv/fabric-nodeenv",
      },
    });

    expect(global.peerImage).toBe("fablo.io/peer/fabric-peer:3.1.0");
    expect(global.toolsImage).toBe("fablo.io/tools/fabric-tools:3.1.3");
    expect(global.nodeenvImage).toBe("fablo.io/nodeenv/fabric-nodeenv:2.5");
    expect(global.ordererImage).toBe("hyperledger/fabric-orderer:3.1.0");
  });

  it("should keep full image references with tag or digest as is", () => {
    const global = extendGlobal({
      fabricVersion: "3.1.0",
      tls: true,
      peerDevMode: false,
      fabricImages: {
        peer: "fablo.io/peer/fabric-peer:dev",
        tools: "fablo.io/tools/fabric-tools@sha256:deadbeef",
      },
    });

    expect(global.peerImage).toBe("fablo.io/peer/fabric-peer:dev");
    expect(global.toolsImage).toBe("fablo.io/tools/fabric-tools@sha256:deadbeef");
  });

  describe("Fabric-X image resolution", () => {
    it("should use pinned default Fabric-X images when provider is fabric-x", () => {
      const global = extendGlobal({
        fabricVersion: "3.1.0",
        tls: true,
        peerDevMode: false,
        provider: "fabric-x",
      });

      expect(global.ordererImage).toBe("ghcr.io/hyperledger/fabric-x-orderer:1.0.0");
      expect(global.committerImage).toBe("ghcr.io/hyperledger/fabric-x-committer:1.0.3");
      expect(global.toolsImage).toBe("ghcr.io/hyperledger/fabric-x-tools:1.0.0");
      expect(global.postgresImage).toBe("docker.io/library/postgres:18.3-alpine3.23");
      expect(global.peerImage).toBeUndefined();
    });

    it("should keep pinned Fabric-X default tags regardless of fabricVersion", () => {
      const global = extendGlobal({
        fabricVersion: "2.5.12",
        tls: true,
        peerDevMode: false,
        provider: "fabric-x",
      });

      expect(global.ordererImage).toBe("ghcr.io/hyperledger/fabric-x-orderer:1.0.0");
      expect(global.committerImage).toBe("ghcr.io/hyperledger/fabric-x-committer:1.0.3");
      expect(global.toolsImage).toBe("ghcr.io/hyperledger/fabric-x-tools:1.0.0");
      expect(global.postgresImage).toBe("docker.io/library/postgres:18.3-alpine3.23");
    });

    it("should append pinned default tags when overriding Fabric-X image repositories without tags", () => {
      const global = extendGlobal({
        fabricVersion: "3.1.0",
        tls: true,
        peerDevMode: false,
        provider: "fabric-x",
        fabricImages: {
          committer: "mirror.local/committer",
          postgres: "mirror.local/postgres",
          orderer: "mirror.local/orderer",
          tools: "mirror.local/tools",
        },
      });

      expect(global.committerImage).toBe("mirror.local/committer:1.0.3");
      expect(global.postgresImage).toBe("mirror.local/postgres:18.3-alpine3.23");
      expect(global.ordererImage).toBe("mirror.local/orderer:1.0.0");
      expect(global.toolsImage).toBe("mirror.local/tools:1.0.0");
    });

    it("should keep custom tags or digests for Fabric-X images as is", () => {
      const global = extendGlobal({
        fabricVersion: "3.1.0",
        tls: true,
        peerDevMode: false,
        provider: "fabric-x",
        fabricImages: {
          committer: "myorg/committer:2.0.0-rc1",
          postgres: "myorg/postgres@sha256:deadbeefcafe",
          orderer: "myorg/orderer:custom-tag",
          tools: "myorg/tools@sha256:1234567890",
        },
      });

      expect(global.committerImage).toBe("myorg/committer:2.0.0-rc1");
      expect(global.postgresImage).toBe("myorg/postgres@sha256:deadbeefcafe");
      expect(global.ordererImage).toBe("myorg/orderer:custom-tag");
      expect(global.toolsImage).toBe("myorg/tools@sha256:1234567890");
    });
  });
});
