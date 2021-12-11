import {ChannelConfig, NetworkSettings, OrgConfig, PeerConfig} from "./FabloConfigExtended";

interface ConnectionProfile {
  name: string;
  description: string;
  version: string;
  client: Client;
  organizations: { [key: string]: Organization };
  peers: { [key: string]: Peer };
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

interface HyperledgerExplorerConnectionProfile {
  name: string;
  description: string;
  version: string;
  peers: { [key: string]: Peer };
  client: HyperledgerExplorerClient;
  organizations: { [key: string]: HyperledgerExplorerOrganization };
  channels: { [name: string]: Channel };
}

interface HyperledgerExplorerClient extends Client {
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

interface HyperledgerExplorerOrganization {
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

function createPeers(isTls: boolean, rootPath: string, orgs: OrgConfig[]): { [key: string]: Peer } {
  const peers: { [key: string]: Peer } = {};
  orgs.forEach((o: OrgConfig) => {
    o.anchorPeers.forEach((p: PeerConfig) => {
      if (isTls) {
        peers[p.address] = {
          url: `grpcs://${p.fullAddress}`,
          tlsCACerts: {
            path: `${rootPath}/peerOrganizations/${o.domain}/tlsca/tlsca.${o.domain}.com-cert.pem`, // todo is it good?
          },
          grpcOptions: {
            "ssl-target-name-override": p.address,
          },
        };
      } else {
        peers[p.address] = {
          url: `grpc://${p.fullAddress}`,
        };
      }
    });
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
        url: org.ca.fullAddress,
        // url: `http://localhost:${org.ca.exposePort}`,
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
      url: org.ca.fullAddress,
      // url: `http://localhost:${org.ca.exposePort}`,
      caName: org.ca.address,
      httpOptions: {
        verify: false,
      },
    },
  };
}

function createChannels(org: OrgConfig, channels: ChannelConfig[]): { [name: string]: Channel } {
  const peers: { [address: string]: unknown } = {};
  const cs: { [name: string]: Channel } = {};
  channels.forEach((channel) => {
    if (channel.orgs.map((o) => o.name).indexOf(org.name) != -1) {
      cs[channel.name] = { peers: peers };
    }
  });
  return cs;
}

export function createConnectionProfile(
  networkSettings: NetworkSettings,
  org: OrgConfig,
  orgs: OrgConfig[],
): ConnectionProfile {
  const rootPath = `${networkSettings.paths.chaincodesBaseDir}/fablo-target/fabric-config/crypto-config`;
  const peers = createPeers(networkSettings.tls, rootPath, orgs);
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
    certificateAuthorities: certificateAuthorities(networkSettings.tls, rootPath, org),
  };
}

export function createHyperledgerExplorerConnectionProfile(
  networkSettings: NetworkSettings,
  org: OrgConfig,
  orgs: OrgConfig[],
  channels: ChannelConfig[],
): HyperledgerExplorerConnectionProfile {
  const rootPath = "/tmp/crypto";
  const peers = createPeers(networkSettings.tls, rootPath, orgs);
  return {
    name: `fablo-test-network-${org.name.toLowerCase()}`,
    description: `Connection profile for Hyperledger Explorer in Fablo network`,
    version: "1.0.0",
    client: {
      organization: org.name,
      tlsEnable: networkSettings.tls,
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
      [org.name]: {
        mspid: org.mspName,
        peers: Object.keys(peers),
        adminPrivateKey: {
          path: `${rootPath}/peerOrganizations/${org.domain}/users/Admin@${org.domain}/msp/keystore/priv-key.pem`,
        },
        signedCert: {
          path: `${rootPath}/peerOrganizations/${org.domain}/users/Admin@${org.domain}/msp/signcerts/Admin@${org.domain}-cert.pem`,
        },
      },
    },
    peers: peers,
    channels: createChannels(org, channels),
  };
}
