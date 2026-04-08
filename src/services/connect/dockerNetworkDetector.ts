import { exec as execCallback } from "child_process";
import { promisify } from "util";

const exec = promisify(execCallback);

export class DockerNetworkDetector {
  constructor(private logger: (msg: string) => void) {}

  async detectNetworks(): Promise<string[]> {
    try {
      // List all networks with the fablo prefix or fabric services attached
      const { stdout } = await exec(
        `docker network ls --filter "label=fablo" --format "{{.Name}}"` +
        ` || docker ps --format "{{.NetworkSettings.Networks}}" | sort | uniq`
      );

      const lines = stdout
        .split("\n")
        .map(line => line.trim())
        .filter(line => line && !line.includes(","));

      if (lines.length > 0) {
        this.logger(`Found networks: ${lines.join(", ")}`);
        return lines;
      }

      // Fallback: look for any network with fabric containers
      return await this.detectNetworkByFabricContainers();
    } catch (error) {
      this.logger(`Warning: Error detecting networks - ${(error as Error).message}`);
      return await this.detectNetworkByFabricContainers();
    }
  }

  private async detectNetworkByFabricContainers(): Promise<string[]> {
    try {
      const { stdout } = await exec(
        `docker ps --filter "label=fabric" --format "{{.Networks}}" 2>/dev/null || ` +
        `docker ps --filter "ancestor=hyperledger/fabric-peer" --format "{{.Networks}}" | sort | uniq`
      );

      const networks = stdout
        .split("\n")
        .map(line => line.trim())
        .filter(line => line && !line.includes(","));

      if (networks.length > 0) {
        return networks;
      }

      // Last fallback: use bridge network
      const { stdout: allNetworks } = await exec(
        `docker network ls --format "{{.Name}}" | grep -E "fabric|fablo" | head -1`
      );

      const network = allNetworks.trim();
      if (network) {
        return [network];
      }

      return [];
    } catch (error) {
      this.logger(`Warning: Could not detect Fabric containers - ${(error as Error).message}`);
      return [];
    }
  }
}
