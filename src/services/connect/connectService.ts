import { FabloConfigJson, ExternalNetworkJson } from "../../types/FabloConfigJson";
import * as path from "path";
import * as fs from "fs-extra";
import { exec as execCallback } from "child_process";
import { promisify } from "util";
import { DockerNetworkDetector } from "./dockerNetworkDetector";
import { PeerConfigurator } from "./peerConfigurator";
import { ChannelJoiner } from "./channelJoiner";

const exec = promisify(execCallback);

export interface ConnectServiceOptions {
  verbose: boolean;
  networkNameOverride?: string;
  logger: (msg: string) => void;
  errorLogger: (msg: string) => never;
}

export class ConnectService {
  private config: FabloConfigJson;
  private workDir: string;
  private options: ConnectServiceOptions;
  private externalNetwork: ExternalNetworkJson;
  private dockerNetwork: string = "";
  private peerConfig: any = null;

  constructor(config: FabloConfigJson, workDir: string, options: ConnectServiceOptions) {
    if (!config.externalNetwork) {
      throw new Error("externalNetwork configuration is required");
    }
    this.config = config;
    this.workDir = workDir;
    this.options = options;
    this.externalNetwork = config.externalNetwork;
    this.validateConfig();
  }

  private validateConfig(): void {
    const ext = this.externalNetwork;

    if (!ext.ordererEndpoint || ext.ordererEndpoint.trim() === "") {
      this.options.errorLogger("externalNetwork.ordererEndpoint is required (format: host:port)");
    }

    if (!ext.channel || ext.channel.trim() === "") {
      this.options.errorLogger("externalNetwork.channel is required");
    }

    if (ext.tls) {
      if (!ext.ca || !ext.ca.url || !ext.ca.tlsCACertPath) {
        this.options.errorLogger("When TLS is enabled, CA configuration with url and tlsCACertPath is required");
      }

      const certPath = path.isAbsolute(ext.ca.tlsCACertPath) 
        ? ext.ca.tlsCACertPath 
        : path.join(this.workDir, ext.ca.tlsCACertPath);

      if (!fs.existsSync(certPath)) {
        this.options.errorLogger(`TLS CA certificate not found at: ${certPath}`);
      }
    }

    // Validate ordererEndpoint format
    if (!ext.ordererEndpoint.includes(":")) {
      this.options.errorLogger("ordererEndpoint must be in format: host:port");
    }

    this.log("Configuration validation passed");
  }

  async connect(): Promise<void> {
    try {
      // Step 1: Get docker network
      this.log("Step 1: Detecting Docker network...");
      await this.detectDockerNetwork();

      // Step 2: Configure peer
      this.log("Step 2: Configuring peer...");
      await this.configurePeer();

      // Step 3: Start peer container
      this.log("Step 3: Starting peer container...");
      await this.startPeerContainer();

      // Step 4: Join channel
      this.log("Step 4: Joining channel...");
      await this.joinChannel();

      this.log("Peer successfully joined the channel!");
    } catch (error) {
      throw error;
    }
  }

  private async detectDockerNetwork(): Promise<void> {
    if (this.options.networkNameOverride) {
      this.dockerNetwork = this.options.networkNameOverride;
      this.log(`Using provided docker network: ${this.dockerNetwork}`);
      return;
    }

    const detector = new DockerNetworkDetector(this.options.logger);
    const networks = await detector.detectNetworks();

    if (networks.length === 0) {
      this.options.errorLogger(
        "Could not detect any running Fabric networks. Please provide --network-name flag or ensure the external network is running."
      );
    }

    // Use the first detected network
    this.dockerNetwork = networks[0];
    this.log(`Detected Docker network: ${this.dockerNetwork}`);
  }

  private async configurePeer(): Promise<void> {
    const orgName = this.getConnectingOrgName();
    const orgDomain = this.getConnectingOrgDomain();

    const configurator = new PeerConfigurator(
      orgName,
      orgDomain,
      this.externalNetwork,
      this.workDir,
      {
        tls: this.config.global.tls,
        logger: this.options.logger,
        errorLogger: this.options.errorLogger,
      }
    );

    this.peerConfig = await configurator.generatePeerConfiguration();
    this.log(`Peer configuration generated for ${orgName}`);
  }

  private async startPeerContainer(): Promise<void> {
    if (!this.peerConfig) {
      throw new Error("Peer configuration not initialized");
    }

    const containerName = `${this.peerConfig.peerName}.${this.peerConfig.orgDomain}`;
    const mspConfigPath = path.join(this.workDir, "fabric-config", this.peerConfig.mspconfigPath);
    const tlsCertsPath = path.join(this.workDir, "fabric-config", this.peerConfig.tlsCertsPath);

    // Check if container already exists
    const containerExists = await this.containerExists(containerName);
    if (containerExists) {
      this.log(`WARNING: Container ${containerName} already exists. Restarting...`);
      await this.restartContainer(containerName);
    } else {
      this.log(`Starting new peer container: ${containerName}`);
      await this.createAndStartContainer(
        containerName,
        mspConfigPath,
        tlsCertsPath,
        this.peerConfig
      );
    }

    this.log(`Peer container started: ${containerName}`);
  }

  private async containerExists(containerName: string): Promise<boolean> {
    try {
      const { stdout } = await exec(`docker ps -a --filter "name=${containerName}" --format "{{.Names}}"`);
      return stdout.trim() === containerName;
    } catch {
      return false;
    }
  }

  private async restartContainer(containerName: string): Promise<void> {
    this.log(`Restarting container: ${containerName}`);
    await exec(`docker restart ${containerName}`);
    // Wait for container to be ready
    await new Promise(resolve => setTimeout(resolve, 3000));
  }

  private async createAndStartContainer(
    containerName: string,
    mspConfigPath: string,
    tlsCertsPath: string,
    peerConfig: any
  ): Promise<void> {
    const peerImage = this.config.global.fabricImages?.peer || `hyperledger/fabric-peer:${this.config.global.fabricVersion}`;
    
    const dockerCmd = [
      "docker run",
      "-d",
      `--name ${containerName}`,
      `--network ${this.dockerNetwork}`,
      `-e CORE_PEER_ID=${peerConfig.peerName}`,
      `-e CORE_PEER_ADDRESS=${peerConfig.peerAddress}`,
      `-e CORE_PEER_LOCALMSPID=${peerConfig.mspId}`,
      `-e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/msp`,
      `-e CORE_PEER_TLS_ENABLED=${this.config.global.tls ? "true" : "false"}`,
      this.config.global.tls
        ? `-e CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/fabric/tls/server.crt`
        : "",
      this.config.global.tls
        ? `-e CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/fabric/tls/server.key`
        : "",
      this.config.global.tls
        ? `-e CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt`
        : "",
      `-e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=${this.dockerNetwork}`,
      `-e CORE_LOGGING_LEVEL=DEBUG`,
      `-v ${mspConfigPath}:/etc/hyperledger/fabric/msp`,
      this.config.global.tls ? `-v ${tlsCertsPath}:/etc/hyperledger/fabric/tls` : "",
      `-w /opt/gopath/src/github.com/hyperledger/fabric/peer`,
      `${peerImage}`,
      "peer node start",
    ].filter(Boolean).join(" ");

    await exec(dockerCmd);
    this.log(`✓ Peer container ${containerName} created and started`);
    
    // Wait for container to be ready
    await this.waitForPeerReady(containerName);
  }

  private async waitForPeerReady(containerName: string, maxRetries: number = 10): Promise<void> {
    for (let i = 0; i < maxRetries; i++) {
      try {
        await exec(`docker exec ${containerName} peer node status`);
        this.log(`Peer container is ready`);
        return;
      } catch {
        if (i < maxRetries - 1) {
          this.log(`Waiting for peer to be ready... (attempt ${i + 1}/${maxRetries})`);
          await new Promise(resolve => setTimeout(resolve, 2000));
        }
      }
    }
    throw new Error(`Peer container ${containerName} did not become ready in time`);
  }

  private async joinChannel(): Promise<void> {
    if (!this.peerConfig) {
      throw new Error("Peer configuration not initialized");
    }

    const channelJoiner = new ChannelJoiner(
      this.externalNetwork,
      this.peerConfig,
      this.workDir,
      {
        tls: this.config.global.tls,
        logger: this.options.logger,
        errorLogger: this.options.errorLogger,
      }
    );

    await channelJoiner.joinChannel();
  }

  private getConnectingOrgName(): string {
    // Get the first non-orderer org with a peer
    for (const org of this.config.orgs) {
      if (org.peer && org.organization.name !== "Orderer") {
        return org.organization.name;
      }
    }
    this.options.errorLogger("No peer organization found in config");
  }

  private getConnectingOrgDomain(): string {
    for (const org of this.config.orgs) {
      if (org.peer && org.organization.name !== "Orderer") {
        return org.organization.domain;
      }
    }
    this.options.errorLogger("No peer organization found in config");
  }

  private log(msg: string): void {
    if (this.options.verbose) {
      this.options.logger(msg);
    }
  }
}
