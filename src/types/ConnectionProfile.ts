import { ChannelConfig, Global, OrgConfig, PeerConfig } from "./FabloConfigExtended";

interface BaseConnectionProfile {
  name: string;
  description: string;
  version: string;
  peers: { [address: string]: Peer };
}

interface ConnectionProfile extends BaseConnectionProfile {
  client: Client;
  organizations: { [key: string]: Organization };
  certificateAuthorities: { [key: string]: CertificateAuthority };
}

interface Client {
  organization: string;
}

interface Organization {
  mspid: string;
  peers: Array<string>;
  certificateAuthorities: Array<string>;
}

interface Peer {
  url: string;
  tlsCACerts?: TlsCACerts;
  grpcOptions?: { [key: string]: string };
}

interface CertificateAuthority {
  url: string;
  caName: string;
  tlsCACerts?: TlsCACerts;
  httpOptions: HttpOptions;
}

interface TlsCACerts {
  path: string;
}

interface HttpOptions {
  verify: boolean;
}

interface ExplorerConnectionProfile extends BaseConnectionProfile {
  client: ExplorerClient;
  organizations: { [key: string]: ExplorerOrganization };
  channels: { [name: string]: Channel };
}

interface ExplorerClient extends Client {
  tlsEnable: boolean;
  adminCredential: {
    id: string;
    password: string;
  };
  enableAuthentication: boolean;
  connection: {
    timeout: {
      peer: {
        endorser: string;
      };
      orderer: string;
    };
  };
}

interface ExplorerOrganization {
  mspid: string;
  peers: Array<string>;
  adminPrivateKey: {
    path: string;
  };
  signedCert: {
    path: string;
  };
}

interface Channel {
  peers: { [address: string]: unknown };
}

export interface OrgWithChannels {
  org: OrgConfig;
  channels: ChannelConfig[];
}

export function pairOrgWithChannels(orgs: OrgConfig[], channels: ChannelConfig[]): OrgWithChannels[] {
  const channelsByOrg: Map<string, ChannelConfig[]> = new Map();

  channels.forEach((c) => {
    c.orgs.forEach((o) => {
      const current = channelsByOrg.get(o.name);
      channelsByOrg.set(o.name, current !== undefined ? current.concat(c) : [c]);
    });
  });

  return orgs
    .map((o) => {
      const c = channelsByOrg.get(o.name);
      return { org: o, channels: c !== undefined ? c : [] };
    })
    .filter((p) => p.channels.length > 0);
}

function createPeers(
  orgName: string,
  isExplorer: boolean,
  isTls: boolean,
  isServiceDiscoveryOn: boolean,
  rootPath: string,
  orgs: OrgConfig[],
): { [key: string]: Peer } {
  const peers: { [key: string]: Peer } = {};
  orgs.forEach((o: OrgConfig) => {
    if ((orgName === o.name && isExplorer) || !isExplorer) {
      o.anchorPeers.forEach((p: PeerConfig) => {
        const tlsCACertsExplorerPath = `${rootPath}/peerOrganizations/${o.domain}/msp/tlscacerts/tlsca.${o.domain}-cert.pem`;
        if (isTls) {
          peers[p.address] = {
            url: isExplorer ? `grpcs://${p.fullAddress}` : `grpcs://localhost:${p.port}`,
            tlsCACerts: {
              path: isExplorer
                ? tlsCACertsExplorerPath
                : `${rootPath}/peerOrganizations/${o.domain}/peers/${p.address}/tls/ca.crt`,
            },
          };
          if (!isExplorer) {
            peers[p.address]["grpcOptions"] = {
              "ssl-target-name-override": p.address,
            };
          }
        } else {
          peers[p.address] = {
            url: isExplorer ? `grpc://${p.fullAddress}` : `grpc://localhost:${p.port}`,
          };
          if (isExplorer) {
            peers[p.address]["tlsCACerts"] = {
              path: tlsCACertsExplorerPath,
            };
          }
        }
      });
    }
  });
  return peers;
}

function certificateAuthorities(
  isTls: boolean,
  rootPath: string,
  org: OrgConfig,
): { [key: string]: CertificateAuthority } {
  if (isTls) {
    return {
      [org.ca.address]: {
        url: `https://localhost:${org.ca.exposePort}`,
        caName: org.ca.address,
        tlsCACerts: {
          path: `${rootPath}/peerOrganizations/${org.domain}/ca/${org.ca.address}-cert.pem`,
        },
        httpOptions: {
          verify: false,
        },
      },
    };
  }
  return {
    [org.ca.address]: {
      url: `http://localhost:${org.ca.exposePort}`,
      caName: org.ca.address,
      httpOptions: {
        verify: false,
      },
    },
  };
}

function createChannels(org: OrgConfig, channels: ChannelConfig[]): { [name: string]: Channel } {
  const cs: { [name: string]: Channel } = {};
  channels
    .filter((c) => c.orgs.map((o) => o.name).indexOf(org.name) > -1)
    .forEach((channel) => {
      cs[channel.name] = { peers: {} };
    });
  return cs;
}

//todo hejwo ===> continure here
export function createConnectionProfile(global: Global, org: OrgConfig, orgs: OrgConfig[]): ConnectionProfile {
  const rootPath = `${global.paths.chaincodesBaseDir}/fablo-target/fabric-config/crypto-config`;
  const peers = createPeers(org.name, false, global.tls, global.serviceDiscoveryOn, rootPath, orgs);
  return {
    name: `fablo-test-network-${org.name.toLowerCase()}`,
    description: `Connection profile for ${org.name} in Fablo network`,
    version: "1.0.0",
    client: {
      organization: org.name,
    },
    organizations: {
      [org.name]: {
        mspid: org.mspName,
        peers: Object.keys(peers),
        certificateAuthorities: [org.ca.address],
      },
    },
    peers: peers,
    certificateAuthorities: certificateAuthorities(global.tls, rootPath, org),
  };
}

export function createExplorerConnectionProfile(
  global: Global,
  p: OrgWithChannels,
  orgs: OrgConfig[],
): ExplorerConnectionProfile {
  const rootPath = "/tmp/crypto";
  const peers = createPeers(p.org.name, true, global.tls, global.serviceDiscoveryOn, rootPath, orgs);
  return {
    name: `fablo-test-network-${p.org.name.toLowerCase()}`,
    description: `Connection profile for Hyperledger Explorer in Fablo network`,
    version: "1.0.0",
    client: {
      organization: p.org.name,
      tlsEnable: global.tls,
      enableAuthentication: true,
      adminCredential: {
        id: "admin",
        password: "adminpw",
      },
      connection: {
        timeout: {
          peer: {
            endorser: "300",
          },
          orderer: "300",
        },
      },
    },
    organizations: {
      [p.org.name]: {
        mspid: p.org.mspName,
        adminPrivateKey: {
          path: `${rootPath}/peerOrganizations/${p.org.domain}/users/Admin@${p.org.domain}/msp/keystore/priv-key.pem`,
        },
        peers: Object.keys(peers),
        signedCert: {
          path: `${rootPath}/peerOrganizations/${p.org.domain}/users/Admin@${p.org.domain}/msp/signcerts/Admin@${p.org.domain}-cert.pem`,
        },
      },
    },
    peers: peers,
    channels: createChannels(p.org, p.channels),
  };
}
