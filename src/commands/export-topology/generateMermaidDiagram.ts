import { FabloConfigExtended, OrdererGroup } from "../../types/FabloConfigExtended";

const safeId = (id: string): string => id.replace(/[^a-zA-Z0-9_]/g, "_");
const ordererGroupId = (g: OrdererGroup): string => safeId(`ord_group_${g.name}_${g.orderers?.[0].address}`);
const channelId = (channelName: string): string => safeId(`channel_${channelName}`);
const chaincodeId = (ccName: string): string => safeId(`chaincode_${ccName}`);

export function generateMermaidDiagram(config: FabloConfigExtended): string {
  const lines: string[] = ["graph LR"];
  lines.push("");
  lines.push("classDef subgraph_padding fill:none,stroke:none");

  // Add organization subgraphs with orderer groups, CA, and peers
  config.orgs?.forEach((org) => {
    const orgId = safeId(org.domain);
    lines.push(`\n  subgraph ${orgId} [Organization: ${org.name}<br>${org.domain}]`);
    const orgPaddingId = `${orgId}_padding`;
    lines.push(`    subgraph ${orgPaddingId} [ ]`);
    lines.push("      direction RL");

    // Orderer groups (nested inside org)
    org.ordererGroups?.forEach((group) => {
      if (group.orderers && group.orderers.length > 0) {
        const consensusLabel = group.consensus ? group.consensus : "";
        const groupId = ordererGroupId(group);
        lines.push(`      subgraph ${groupId} [Orderer Group: ${group.name}<br>${consensusLabel}]`);
        const groupPaddingId = `${groupId}_padding`;
        lines.push(`        subgraph ${groupPaddingId} [ ]`);
        lines.push("          direction RL");
        group.orderers.forEach((orderer) => {
          lines.push(`          ${safeId(orderer.address)}[${orderer.address}]`);
        });
        lines.push(`        end`);
        lines.push(`        class ${groupPaddingId} subgraph_padding`);
        lines.push("      end");
      }
    });

    // CA (at same level as orderer groups)
    if (org.ca) {
      const caAddress = org.ca.address;
      const caLabel = org.ca.db ? `${caAddress}<br>${org.ca.db}` : `${caAddress}`;
      lines.push(`      ${safeId(caAddress)}([${caLabel}])`);
    }

    // Peers (at same level as orderer groups)
    org.peers?.forEach((peer) => {
      const peerLabel = `${peer.address}<br>${peer.db.type}`;
      lines.push(`      ${safeId(peer.address)}[${peerLabel}]`);
    });

    lines.push("    end");
    lines.push(`    class ${orgPaddingId} subgraph_padding`);
    lines.push("  end");
  });

  // Add channel subgraphs with chaincodes
  config.channels?.forEach((channel) => {
    const chId = channelId(channel.name);
    lines.push(`\n  subgraph ${chId} [Channel: ${channel.name}]`);
    const chPaddingId = `${chId}_padding`;
    lines.push(`    subgraph ${chPaddingId} [ ]`);

    // Add chaincodes for this channel (using cylinder shape)
    const channelChaincodes = config.chaincodes?.filter((cc) => cc.channel?.name === channel.name) ?? [];
    channelChaincodes.forEach((cc) => {
      lines.push(`      ${chaincodeId(cc.name)}[[Chaincode: ${cc.name}]]`);
    });

    // Add dummy invisible node for empty channels to ensure visibility
    if (channelChaincodes.length === 0) {
      const emptyNodeId = `${chId}_empty`;
      lines.push(`      ${emptyNodeId}[" "]`);
      lines.push(`      style ${emptyNodeId} fill:#ffffff00,stroke:#ffffff00`);
    }

    lines.push("    end");
    lines.push(`    class ${chPaddingId} subgraph_padding`);
    lines.push("  end");
  });

  // Add connections
  lines.push("\n  %% Connections");

  // Connect peers to channels
  config.channels?.forEach((channel) => {
    const channelIdStr = channelId(channel.name);

    channel.orgs?.forEach((orgOnChannel) => {
      orgOnChannel.peers?.forEach((peer) => {
        lines.push(`  ${safeId(peer.address)} --> ${channelIdStr}`);
      });
    });
  });

  // Connect channels to orderer groups (reversed direction)
  config.channels?.forEach((channel) => {
    const channelIdStr = channelId(channel.name);
    const ogId = ordererGroupId(channel.ordererGroup);
    lines.push(`  ${channelIdStr} --> ${ogId}`);
  });

  return lines.join("\n");
}
