import { NetworkSettings, OrgConfig, PeerConfig } from "./FabloConfigExtended";

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

function createPeers(isTls: boolean, rootPath: string, orgs: OrgConfig[]): { [key: string]: Peer } {
  const peers: { [key: string]: Peer } = {};
  orgs.forEach((o: OrgConfig) => {
    o.anchorPeers.forEach((p: PeerConfig) => {
      if (isTls) {
        peers[p.address] = {
          url: `grpcs://localhost:${p.port}`,
          tlsCACerts: {
            path: `${rootPath}/fablo-target/fabric-config/crypto-config/peerOrganizations/${o.domain}/peers/${p.address}/tls/ca.crt`,
          },
          grpcOptions: {
            "ssl-target-name-override": p.address,
          },
        };
      } else {
        peers[p.address] = {
          url: `grpc://localhost:${p.port}`,
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
        url: `http://localhost:${org.ca.exposePort}`,
        caName: org.ca.address,
        tlsCACerts: {
          path: `${rootPath}/fablo-target/fabric-config/crypto-config/peerOrganizations/${org.domain}/ca/${org.ca.address}-cert.pem`,
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

export function createConnectionProfile(
  networkSettings: NetworkSettings,
  org: OrgConfig,
  orgs: OrgConfig[],
): ConnectionProfile {
  const rootPath = networkSettings.paths.chaincodesBaseDir;
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
