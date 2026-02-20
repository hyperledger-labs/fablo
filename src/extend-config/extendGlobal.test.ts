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

    expect(global.toolsImage).toBe("ghcr.io/fablo-io/fabric-tools:3.0.0");
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
    expect(global.toolsImage).toBe("fablo.io/tools/fabric-tools:3.0.0");
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
});
