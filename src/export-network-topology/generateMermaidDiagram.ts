import { FabloConfigExtended } from "../types/FabloConfigExtended";

function safeId(id: string): string {
  return id.replace(/[^a-zA-Z0-9_]/g, "_");
}

export function generateMermaidDiagram(config: FabloConfigExtended): string {
  let diagram = "graph TD\n";

  if (Array.isArray(config.orgs)) {
    config.orgs.forEach((org: any) => {
      const orgName = org.name || org?.organization?.name || "undefined";
      const orgId = safeId(`Org_${orgName}`);
      diagram += `\n  subgraph ${orgId} [Org: ${orgName}]\n`;

      if (org.ca) {
        const caName = org.ca.prefix ? `${org.ca.prefix}_${orgName}` : `ca_${orgName}`;
        const caId = safeId(`CA_${caName}`);
        const caLabel = org.ca.db ? `CA: ${caName} - ${org.ca.db}` : `CA: ${caName}`;
        diagram += `    ${caId}[${caLabel}]\n`;
      }

      if (Array.isArray(org.peers)) {
        org.peers.forEach((peer: any) => {
          const peerName = peer.name || peer || "undefined";
          const peerId = safeId(`${orgName}_${peerName}`);
          diagram += `    ${peerId}[Peer: ${peerName}]\n`;
        });
      } else if (org?.peer && typeof org.peer.instances === "number") {
        for (let i = 0; i < org.peer.instances; i++) {
          const peerName = org.peer.prefix ? `${org.peer.prefix}${i}` : `peer${i}`;
          const peerId = safeId(`${orgName}_${peerName}`);
          diagram += `    ${peerId}[Peer: ${peerName}]\n`;
        }
      }

      if (Array.isArray(org.orderers)) {
        org.orderers.forEach((orderer: any) => {
          const prefix = orderer.prefix || "orderer";
          const instances = orderer.instances || 1;
          for (let i = 0; i < instances; i++) {
            const ordererName = `${prefix}${i}`;
            const ordererId = safeId(`${orgName}_${ordererName}`);
            const label = `Orderer: ${ordererName}${orderer.type ? ` - ${orderer.type}` : ""}`;
            diagram += `    ${ordererId}[${label}]\n`;
          }
        });
      } else if (org.orderer && typeof org.orderer.instances === "number") {
        const prefix = org.orderer.prefix || "orderer";
        const instances = org.orderer.instances;
        for (let i = 0; i < instances; i++) {
          const ordererName = `${prefix}${i}`;
          const ordererId = safeId(`${orgName}_${ordererName}`);
          const label = `Orderer: ${ordererName}${org.orderer.type ? ` - ${org.orderer.type}` : ""}`;
          diagram += `    ${ordererId}[${label}]\n`;
        }
      }

      diagram += "  end\n";
    });
  }

  if (Array.isArray(config.channels)) {
    config.channels.forEach((channel) => {
      const channelId = safeId(`Channel_${channel.name}`);
      diagram += `\n  subgraph ${channelId} [Channel: ${channel.name}]\n`;
      // Add chaincodes belonging to this channel
      if (Array.isArray(config.chaincodes)) {
        config.chaincodes.forEach((cc) => {
          if (
            cc.channel &&
            ((typeof cc.channel === "string" && cc.channel === channel.name) ||
              (cc.channel.name && cc.channel.name === channel.name))
          ) {
            const ccId = safeId(`Chaincode_${cc.name}`);
            diagram += `    ${ccId}[Chaincode: ${cc.name}]\n`;
          }
        });
      }
      diagram += `  end\n`;
    });
  }

  diagram += "\n  %% Connections\n";

  if (Array.isArray(config.orgs)) {
    config.orgs.forEach((org: any) => {
      const orgName = org.name || org?.organization?.name || "undefined";
      if (orgName.includes("Orderer")) {
        if (Array.isArray(config.channels)) {
          const orgId = safeId(`Org_${orgName}`);
          config.channels.forEach((channel) => {
            const channelId = safeId(`Channel_${channel.name}`);
            diagram += `  ${orgId} --> ${channelId}\n`;
          });
        }
      }
    });
  }

  if (Array.isArray(config.channels)) {
    config.channels.forEach((channel) => {
      const channelId = safeId(`Channel_${channel.name}`);
      if (Array.isArray(channel.orgs)) {
        channel.orgs.forEach((orgOnChannel) => {
          const orgName = orgOnChannel.name || ((orgOnChannel as any)?.organization?.name as string) || "undefined";
          const fullOrgDef = config.orgs.find((o: any) => (o.name || o?.organization?.name) === orgName);

          if (fullOrgDef) {
            const hasPeers =
              (Array.isArray(fullOrgDef.peers) && fullOrgDef.peers.length > 0) ||
              (fullOrgDef as any)?.peer?.instances > 0;

            if (hasPeers) {
              const orgId = safeId(`Org_${orgName}`);
              diagram += `  ${orgId} -.-> ${channelId}\n`;
            }

            if (Array.isArray(fullOrgDef.peers)) {
              fullOrgDef.peers.forEach((peer: any) => {
                const peerName = typeof peer === "string" ? peer : peer.name;
                const peerId = safeId(`${orgName}_${peerName}`);
                diagram += `  ${peerId} --> ${channelId}\n`;
              });
            } else if ((fullOrgDef as any)?.peer?.instances) {
              for (let i = 0; i < (fullOrgDef as any).peer.instances; i++) {
                const peerName = (fullOrgDef as any).peer.prefix
                  ? `${(fullOrgDef as any).peer.prefix}${i}`
                  : `peer${i}`;
                const peerId = safeId(`${orgName}_${peerName}`);
                diagram += `  ${peerId} --> ${channelId}\n`;
              }
            }
          }
        });
      }
    });
  }

  return diagram;
}
