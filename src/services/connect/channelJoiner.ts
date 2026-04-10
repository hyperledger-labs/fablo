import { ExternalNetworkJson } from "../../types/FabloConfigJson";
import * as path from "path";
import { exec as execCallback } from "child_process";
import { promisify } from "util";
import { PeerConfiguration } from "./peerConfigurator";

const exec = promisify(execCallback);

export interface ChannelJoinerOptions {
  tls: boolean;
  logger: (msg: string) => void;
  errorLogger: (msg: string) => never;
}

export class ChannelJoiner {
  private maxRetries: number = 5;
  private retryDelay: number = 3000; // 3 seconds

  constructor(
    private externalNetwork: ExternalNetworkJson,
    private peerConfig: PeerConfiguration,
    private workDir: string,
    private options: ChannelJoinerOptions
  ) {}

  async joinChannel(): Promise<void> {
    const channelName = this.externalNetwork.channel;
    const containerName = `${this.peerConfig.peerName}.${this.peerConfig.orgDomain}`;

    // Check if already joined
    const alreadyJoined = await this.isAlreadyJoinedChannel(containerName, channelName);
    if (alreadyJoined) {
      this.options.logger(`⚠️  Peer is already joined to channel '${channelName}'`);
      return;
    }

    // Fetch channel block and join with retries
    await this.fetchAndJoinChannelWithRetry(containerName, channelName);
  }

  private async isAlreadyJoinedChannel(containerName: string, channelName: string): Promise<boolean> {
    try {
      const cmd = `docker exec ${containerName} peer channel list 2>&1`;
      const { stdout, stderr } = await exec(cmd);
      const output = stdout + stderr;
      return output.includes(channelName);
    } catch {
      // If the peer isn't ready yet, assume not joined
      return false;
    }
  }

  private async fetchAndJoinChannelWithRetry(containerName: string, channelName: string): Promise<void> {
    for (let attempt = 1; attempt <= this.maxRetries; attempt++) {
      try {
        this.options.logger(`Attempt ${attempt}/${this.maxRetries}: Fetching channel block...`);
        
        // Fetch the channel block
        await this.fetchChannelBlock(containerName, channelName);

        // Join the channel
        await this.joinChannelBlock(containerName, channelName);

        this.options.logger(`Successfully joined channel '${channelName}'`);
        return;
      } catch (error) {
        const errorMsg = (error as Error).message;
        this.options.logger(`Attempt ${attempt} failed: ${errorMsg}`);

        if (attempt < this.maxRetries) {
          this.options.logger(`Retrying in ${this.retryDelay / 1000} seconds...`);
          await new Promise(resolve => setTimeout(resolve, this.retryDelay));
        } else {
          throw new Error(`Failed to join channel '${channelName}' after ${this.maxRetries} attempts: ${errorMsg}`);
        }
      }
    }
  }

  private async fetchChannelBlock(
    containerName: string,
    channelName: string
  ): Promise<void> {
    const fetchCmd = this.buildFetchCommand(channelName);
    
    try {
      await exec(`docker exec ${containerName} ${fetchCmd}`);
      this.options.logger(`Channel block fetched for '${channelName}'`);
    } catch (error) {
      const errorMsg = (error as Error).message;
      
      if (errorMsg.includes("NOT_FOUND")) {
        throw new Error(`Channel '${channelName}' not found on orderer`);
      } else if (errorMsg.includes("UNAVAILABLE")) {
        throw new Error(`Orderer at ${this.externalNetwork.ordererEndpoint} is unreachable`);
      } else if (errorMsg.includes("Decipher")) {
        throw new Error(`TLS certificate error - verify CA certificate path and TLS settings`);
      }
      throw new Error(`Failed to fetch channel block: ${errorMsg}`);
    }
  }

  private buildFetchCommand(channelName: string): string {
    const baseCmd = `peer channel fetch 0 ${channelName}.block -o ${this.externalNetwork.ordererEndpoint} -c ${channelName}`;

    if (this.options.tls) {
      const tlsCert = path.isAbsolute(this.externalNetwork.ca.tlsCACertPath)
        ? this.externalNetwork.ca.tlsCACertPath
        : path.join(this.workDir, this.externalNetwork.ca.tlsCACertPath);

      return `${baseCmd} --tls --cafile ${tlsCert}`;
    }

    return baseCmd;
  }

  private async joinChannelBlock(
    containerName: string,
    channelName: string
  ): Promise<void> {
    const joinCmd = this.buildJoinCommand(channelName);

    try {
      await exec(`docker exec ${containerName} ${joinCmd}`);
      this.options.logger(`Peer joined channel '${channelName}'`);
    } catch (error) {
      const errorMsg = (error as Error).message;
      throw new Error(`Failed to join channel: ${errorMsg}`);
    }
  }

  private buildJoinCommand(channelName: string): string {
    const baseCmd = `peer channel join -b ${channelName}.block`;

    if (this.options.tls) {
      const tlsCert = path.isAbsolute(this.externalNetwork.ca.tlsCACertPath)
        ? this.externalNetwork.ca.tlsCACertPath
        : path.join(this.workDir, this.externalNetwork.ca.tlsCACertPath);

      return `${baseCmd} --tls --cafile ${tlsCert}`;
    }

    return baseCmd;
  }
}
