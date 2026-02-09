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

    expect(global.peerImage).toBe("hyperledger/fabric-peer:${FABRIC_VERSION}");
    expect(global.ordererImage).toBe("hyperledger/fabric-orderer:${FABRIC_VERSION}");
    expect(global.caImage).toBe("hyperledger/fabric-ca:${FABRIC_CA_VERSION}");
    expect(global.toolsImage).toBe("hyperledger/fabric-tools:${FABRIC_TOOLS_VERSION}");
    expect(global.ccenvImage).toBe("hyperledger/fabric-ccenv:${FABRIC_CCENV_VERSION}");
    expect(global.baseosImage).toBe("hyperledger/fabric-baseos:${FABRIC_BASEOS_VERSION}");
    expect(global.javaenvImage).toBe("hyperledger/fabric-javaenv:${FABRIC_JAVAENV_VERSION}");
    expect(global.nodeenvImage).toBe("hyperledger/fabric-nodeenv:${FABRIC_NODEENV_VERSION}");
  });

  it("should use ghcr tools image by default for Fabric 3.x", () => {
    const global = extendGlobal({
      fabricVersion: "3.1.0",
      tls: true,
      peerDevMode: false,
    });

    expect(global.toolsImage).toBe("ghcr.io/fablo-io/fabric-tools:${FABRIC_TOOLS_VERSION}");
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

    expect(global.peerImage).toBe("fablo.io/peer/fabric-peer:${FABRIC_VERSION}");
    expect(global.toolsImage).toBe("fablo.io/tools/fabric-tools:${FABRIC_TOOLS_VERSION}");
    expect(global.nodeenvImage).toBe("fablo.io/nodeenv/fabric-nodeenv:${FABRIC_NODEENV_VERSION}");
    expect(global.ordererImage).toBe("hyperledger/fabric-orderer:${FABRIC_VERSION}");
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
