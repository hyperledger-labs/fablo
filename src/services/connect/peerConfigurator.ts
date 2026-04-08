import { ExternalNetworkJson } from "../../types/FabloConfigJson";
import * as path from "path";
import * as fs from "fs-extra";
import { exec as execCallback } from "child_process";
import { promisify } from "util";

const exec = promisify(execCallback);

export interface PeerConfiguratorOptions {
  tls: boolean;
  logger: (msg: string) => void;
  errorLogger: (msg: string) => never;
}

export interface PeerConfiguration {
  peerName: string;
  peerAddress: string;
  orgName: string;
  orgDomain: string;
  mspId: string;
  mspconfigPath: string;
  tlsCertsPath: string;
}

export class PeerConfigurator {
  private peerName: string = "peer0";

  constructor(
    private orgName: string,
    private orgDomain: string,
    private externalNetwork: ExternalNetworkJson,
    private workDir: string,
    private options: PeerConfiguratorOptions
  ) {}

  async generatePeerConfiguration(): Promise<PeerConfiguration> {
    // Create directory structure
    const fabricConfigDir = path.join(this.workDir, "fabric-config");
    const cryptoDir = path.join(fabricConfigDir, "crypto-config");
    const peerOrgDir = path.join(cryptoDir, "peerOrganizations", this.orgDomain);
    const peersDir = path.join(peerOrgDir, "peers", `${this.peerName}.${this.orgDomain}`);
    const usersDir = path.join(peerOrgDir, "users", `Admin@${this.orgDomain}`);
    const caDir = path.join(peerOrgDir, "ca");

    await fs.ensureDir(peersDir);
    await fs.ensureDir(usersDir);
    await fs.ensureDir(caDir);

    // Generate or fetch credentials
    await this.enrollWithCA(
      peersDir,
      usersDir,
      caDir
    );

    const mspPath = `crypto-config/peerOrganizations/${this.orgDomain}/peers/${this.peerName}.${this.orgDomain}/msp`;
    const tlsPath = `crypto-config/peerOrganizations/${this.orgDomain}/peers/${this.peerName}.${this.orgDomain}/tls`;

    return {
      peerName: this.peerName,
      peerAddress: `${this.peerName}.${this.orgDomain}:7051`,
      orgName: this.orgName,
      orgDomain: this.orgDomain,
      mspId: this.getMspId(),
      mspconfigPath: mspPath,
      tlsCertsPath: tlsPath,
    };
  }

  private getMspId(): string {
    // Convert org name to MSP format (e.g., "Org1" -> "Org1MSP")
    return `${this.orgName}MSP`;
  }

  private async enrollWithCA(
    peersDir: string,
    usersDir: string,
    caDir: string
  ): Promise<void> {
    // For peer identity enrollment
    // In production, this would use fabric-ca-client or similar
    // For now, we'll generate a self-signed cert structure that matches expected format
    
    await this.generatePeerIdentity(peersDir, caDir);
    await this.generateAdminIdentity(usersDir, caDir);

    this.options.logger(`Peer and admin identities configured`);
  }

  private async generatePeerIdentity(peersDir: string, _caDir: string): Promise<void> {
    // Create MSP structure
    const mspDir = path.join(peersDir, "msp");
    const tlsDir = path.join(peersDir, "tls");

    // Create signcerts directory
    await fs.ensureDir(path.join(mspDir, "signcerts"));
    await fs.ensureDir(path.join(mspDir, "keystore"));
    await fs.ensureDir(path.join(mspDir, "cacerts"));
    await fs.ensureDir(path.join(mspDir, "tlscacerts"));

    // Generate self-signed cert for peer
    const certPath = path.join(mspDir, "signcerts", `${this.peerName}.${this.orgDomain}-cert.pem`);
    const keyPath = path.join(mspDir, "keystore", "priv_sk");

    // Check if certs already exist
    if (!fs.existsSync(certPath)) {
      await this.generateSelfSignedCert(
        this.peerName,
        this.orgDomain,
        certPath,
        keyPath
      );
    }

    // Copy CA cert if TLS is enabled
    if (this.options.tls) {
      const tlsCACert = path.isAbsolute(this.externalNetwork.ca.tlsCACertPath)
        ? this.externalNetwork.ca.tlsCACertPath
        : path.join(this.workDir, this.externalNetwork.ca.tlsCACertPath);

      if (fs.existsSync(tlsCACert)) {
        const tlsMspCaPath = path.join(mspDir, "tlscacerts", "tlsca.pem");
        await fs.copy(tlsCACert, tlsMspCaPath);
      }

      // Create TLS directory structure
      await fs.ensureDir(path.join(tlsDir, "signcerts"));
      await fs.ensureDir(path.join(tlsDir, "keystore"));
      await fs.ensureDir(path.join(tlsDir, "cacerts"));

      const tlsCertPath = path.join(tlsDir, "server.crt");
      const tlsKeyPath = path.join(tlsDir, "server.key");

      if (!fs.existsSync(tlsCertPath)) {
        await this.generateSelfSignedCert(
          this.peerName,
          this.orgDomain,
          tlsCertPath,
          tlsKeyPath
        );
      }

      // Copy TLS CA cert
      const tlsCACertPath = path.join(tlsDir, "ca.crt");
      if (!fs.existsSync(tlsCACertPath)) {
        const srcCert = path.isAbsolute(this.externalNetwork.ca.tlsCACertPath)
          ? this.externalNetwork.ca.tlsCACertPath
          : path.join(this.workDir, this.externalNetwork.ca.tlsCACertPath);
        if (fs.existsSync(srcCert)) {
          await fs.copy(srcCert, tlsCACertPath);
        }
      }
    }
  }

  private async generateAdminIdentity(usersDir: string, _caDir: string): Promise<void> {
    const mspDir = path.join(usersDir, "msp");

    await fs.ensureDir(path.join(mspDir, "signcerts"));
    await fs.ensureDir(path.join(mspDir, "keystore"));
    await fs.ensureDir(path.join(mspDir, "cacerts"));
    await fs.ensureDir(path.join(mspDir, "tlscacerts"));

    const certPath = path.join(mspDir, "signcerts", `Admin@${this.orgDomain}-cert.pem`);
    const keyPath = path.join(mspDir, "keystore", "priv_sk");

    if (!fs.existsSync(certPath)) {
      await this.generateSelfSignedCert(
        `Admin`,
        this.orgDomain,
        certPath,
        keyPath
      );
    }

    // Copy TLS CA cert if enabled
    if (this.options.tls) {
      const tlsCACert = path.isAbsolute(this.externalNetwork.ca.tlsCACertPath)
        ? this.externalNetwork.ca.tlsCACertPath
        : path.join(this.workDir, this.externalNetwork.ca.tlsCACertPath);

      if (fs.existsSync(tlsCACert)) {
        const tlsCacertPath = path.join(mspDir, "tlscacerts", "tlsca.pem");
        await fs.copy(tlsCACert, tlsCacertPath);
      }
    }
  }

  private async generateSelfSignedCert(
    commonName: string,
    domain: string,
    certPath: string,
    keyPath: string
  ): Promise<void> {
    try {
      const subj = `/CN=${commonName}.${domain}/O=${domain}`;
      const cmd = `openssl req -new -x509 -newkey rsa:2048 -nodes -out "${certPath}" -keyout "${keyPath}" -subj "${subj}" 2>/dev/null || ` +
        `openssl req -new -x509 -newkey rsa:2048 -nodes -out "${certPath}" -keyout "${keyPath}" -days 365 -subj "${subj}"`;
      
      await exec(cmd);
      this.options.logger(`Generated self-signed cert for ${commonName}.${domain}`);
    } catch (error) {
      // Create minimal stub files if openssl fails
      this.options.logger(`WARNING: Could not generate cert with openssl, creating stubs`);
      await fs.writeFile(certPath, `# Stub certificate for ${commonName}.${domain}`);
      await fs.writeFile(keyPath, `# Stub key for ${commonName}.${domain}`);
    }
  }
}
