import { FabloConfigExtended } from "../types/FabloConfigExtended";

const safeId = (id: string): string => id.replace(/[^a-zA-Z0-9_]/g, "_");

const orgId = (orgName: string): string => safeId(`Org_${orgName}`);
const caId = (caName: string): string => safeId(`CA_${caName}`);
const peerId = (orgName: string, peerName: string): string => safeId(`${orgName}_${peerName}`);
const ordererId = (ordererName: string): string => safeId(`Orderer_${ordererName}`);
const channelId = (channelName: string): string => safeId(`Channel_${channelName}`);
const chaincodeId = (ccName: string): string => safeId(`Chaincode_${ccName}`);
const ordererGroupId = (groupName: string): string => safeId(`OrdererGroup_${groupName}`);

export function generateMermaidDiagram(config: FabloConfigExtended): string {
  const lines: string[] = ["graph TD"];

  // Add organization subgraphs with orderer groups, CA, and peers
  config.orgs?.forEach((org) => {
    const orgName = org.name;
    lines.push(`\n  subgraph ${orgId(orgName)} [Org: ${orgName}]`);
    lines.push("    direction RL");

    // Orderer groups (nested inside org)
    org.ordererGroups?.forEach((group) => {
      if (group.orderers && group.orderers.length > 0) {
        const consensusLabel = group.consensus ? ` ${group.consensus}` : "";
        lines.push(`    subgraph ${ordererGroupId(group.name)} [Orderer Group: ${group.name}${consensusLabel}]`);
        lines.push("      direction RL");
        group.orderers.forEach((orderer) => {
          const ordererLabel = `Orderer: ${orderer.name}${group.consensus ? ` - ${group.consensus}` : ""}`;
          lines.push(`      ${ordererId(orderer.name)}[${ordererLabel}]`);
        });
        lines.push("    end");
      }
    });

    // CA (at same level as orderer groups) - using hexagon shape
    if (org.ca) {
      const caName = org.ca.prefix ? `${org.ca.prefix}_${orgName}` : `ca_${orgName}`;
      const caLabel = org.ca.db ? `CA: ${caName} - ${org.ca.db}` : `CA: ${caName}`;
      lines.push(`    ${caId(caName)}{${caLabel}}`);
    }

    // Peers (at same level as orderer groups)
    org.peers?.forEach((peer) => {
      lines.push(`    ${peerId(orgName, peer.name)}[Peer: ${peer.name}]`);
    });

    lines.push("  end");
  });

  // Add channel subgraphs with chaincodes
  config.channels?.forEach((channel) => {
    lines.push(`\n  subgraph ${channelId(channel.name)} [Channel: ${channel.name}]`);

    // Add chaincodes for this channel (using cylinder shape)
    const channelChaincodes = config.chaincodes?.filter((cc) => cc.channel?.name === channel.name) ?? [];
    channelChaincodes.forEach((cc) => {
      lines.push(`    ${chaincodeId(cc.name)}[[Chaincode: ${cc.name}]]`);
    });

    // Add dummy invisible node for empty channels to ensure visibility
    if (channelChaincodes.length === 0) {
      const emptyNodeId = `${channelId(channel.name)}_empty`;
      lines.push(`    ${emptyNodeId}[" "]`);
      lines.push(`    style ${emptyNodeId} fill:#ffffff00,stroke:#ffffff00`);
    }

    lines.push("  end");
  });

  // Add connections
  lines.push("\n  %% Connections");

  // Connect peers to channels
  config.channels?.forEach((channel) => {
    const channelIdStr = channelId(channel.name);

    channel.orgs?.forEach((orgOnChannel) => {
      const org = config.orgs?.find((o) => o.name === orgOnChannel.name);
      if (!org) return;

      // Connect peers to channel
      org.peers?.forEach((peer) => {
        lines.push(`  ${peerId(org.name, peer.name)} --> ${channelIdStr}`);
      });
    });
  });

  // Connect channels to orderer groups (reversed direction)
  config.channels?.forEach((channel) => {
    const channelIdStr = channelId(channel.name);
    const og = channel.ordererGroup;

    if (og) {
      const ogId = ordererGroupId(og.name);
      lines.push(`  ${channelIdStr} --> ${ogId}`);
    }
  });

  return lines.join("\n");
}
