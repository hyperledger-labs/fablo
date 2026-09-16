import * as yaml from "js-yaml";
import { FabloConfigJson } from "../types/FabloConfigJson";
import { ChaincodeConfig, FabloConfigExtended } from "../types/FabloConfigExtended";
import defaults from "../extend-config/defaults";

const FABRICOPS_API_VERSION = "fabricops.io/v1alpha1";
const DEFAULT_FABRICNETWORK_NAME = "fablo-network";
const DEFAULT_SUCCEEDED_JOB_HISTORY_TTL_SECONDS = 600;

interface FabricOpsManifest {
  apiVersion: string;
  kind: "FabricNetwork";
  metadata: {
    name: string;
    labels: Record<string, string>;
  };
  spec: Record<string, unknown>;
}

const ordererTypeForFabricOps = (consensus: string): string => (consensus === "etcdraft" ? "raft" : consensus);

const requireCcaasImages = (chaincodes: ChaincodeConfig[]): void => {
  const unsupported = chaincodes.filter((chaincode) => chaincode.lang !== "ccaas" || !chaincode.image);
  if (unsupported.length === 0) return;

  const names = unsupported.map((chaincode) => `${chaincode.channel.name}/${chaincode.name}`).join(", ");
  throw new Error(
    `FabricOps Kubernetes engine requires CCaaS chaincodes with image fields. Unsupported chaincodes: ${names}`,
  );
};

const requireFabricOpsCompatibleTopology = (json: FabloConfigJson, config: FabloConfigExtended): void => {
  if (config.channels.length > 0 && !config.global.tls) {
    throw new Error("FabricOps Kubernetes engine requires global.tls=true when channels are declared");
  }

  if (config.ordererGroups.length > 1) {
    throw new Error("FabricOps Kubernetes engine currently supports one orderer group");
  }

  const orgsWithTools = json.orgs
    .filter((org) => org.tools?.fabloRest || org.tools?.explorer)
    .map((org) => org.organization.name);
  if (orgsWithTools.length > 0 || json.global.tools?.explorer) {
    throw new Error(
      `FabricOps Kubernetes engine does not yet support Fablo REST or Explorer tools. Unsupported orgs: ${
        orgsWithTools.join(", ") || "global"
      }`,
    );
  }

  const chaincodesWithDevOptions = json.chaincodes
    .filter((chaincode) => chaincode.chaincodeMountPath || chaincode.chaincodeStartCommand)
    .map((chaincode) => `${chaincode.channel}/${chaincode.name}`);
  if (chaincodesWithDevOptions.length > 0) {
    throw new Error(
      `FabricOps Kubernetes engine requires prebuilt CCaaS images and does not support chaincodeMountPath or chaincodeStartCommand. Unsupported chaincodes: ${chaincodesWithDevOptions.join(
        ", ",
      )}`,
    );
  }
};

const withoutUndefined = (value: unknown): unknown => {
  if (Array.isArray(value)) return value.map(withoutUndefined);
  if (value === null || typeof value !== "object") return value;

  return Object.fromEntries(
    Object.entries(value as Record<string, unknown>)
      .filter(([, v]) => v !== undefined)
      .map(([k, v]) => [k, withoutUndefined(v)]),
  );
};

const policyOrgNames = (chaincode: ChaincodeConfig, policy: string): string[] => {
  const orgNameByMsp = new Map(chaincode.channel.orgs.map((org) => [org.mspName, org.name]));
  return (
    policy
      .match(/'([^']+)\.member'/g)
      ?.map((msp) => msp.replace(/^'/, "").replace(/\.member'$/, ""))
      .map((mspName) => orgNameByMsp.get(mspName) ?? mspName) ?? []
  );
};

const privateDataForFabricOps = (chaincode: ChaincodeConfig): Record<string, unknown>[] =>
  chaincode.privateData.map(
    (collection) =>
      withoutUndefined({
        name: collection.name,
        orgNames: policyOrgNames(chaincode, collection.policy),
        policy: collection.policy,
        requiredPeerCount: collection.requiredPeerCount,
        maxPeerCount: collection.maxPeerCount,
        blockToLive: collection.blockToLive,
        memberOnlyRead: collection.memberOnlyRead,
        memberOnlyWrite: collection.memberOnlyWrite,
      }) as Record<string, unknown>,
  );

const toFabricOpsManifest = (json: FabloConfigJson, config: FabloConfigExtended): FabricOpsManifest => {
  requireCcaasImages(config.chaincodes);
  requireFabricOpsCompatibleTopology(json, config);

  const orgsByName = new Map(json.orgs.map((org) => [org.organization.name, org]));

  return withoutUndefined({
    apiVersion: FABRICOPS_API_VERSION,
    kind: "FabricNetwork",
    metadata: {
      name: DEFAULT_FABRICNETWORK_NAME,
      labels: {
        "app.kubernetes.io/name": "fabricops",
        "app.kubernetes.io/managed-by": "fablo",
      },
    },
    spec: withoutUndefined({
      global: {
        fabricVersion: config.global.fabricVersion,
        tls: config.global.tls,
        jobs: {
          succeededHistoryTTLSeconds: DEFAULT_SUCCEEDED_JOB_HISTORY_TTL_SECONDS,
        },
      },
      orgs: config.orgs.map((org) => {
        const orgJson = orgsByName.get(org.name);
        return {
          organization: {
            name: org.name,
            domain: org.domain,
            mspName: org.mspName,
          },
          ca: {
            db: org.ca.db,
          },
          ...(org.ordererGroups.length > 0
            ? {
                orderers: org.ordererGroups.map((group) => {
                  const groupJson = orgJson?.orderers?.find((o) => o.groupName === group.name);
                  return {
                    groupName: group.name,
                    type: ordererTypeForFabricOps(group.consensus),
                    instances: group.orderers.length,
                    prefix: groupJson?.prefix ?? defaults.orderer.prefix,
                  };
                }),
              }
            : {}),
          ...(org.peers.length > 0
            ? {
                peer: {
                  instances: org.peers.length,
                  db: org.headPeer?.db.type ?? orgJson?.peer?.db ?? defaults.peer.db,
                  prefix: orgJson?.peer?.prefix ?? defaults.peer.prefix,
                },
              }
            : {}),
        };
      }),
      channels: config.channels.map((channel) => ({
        name: channel.name,
        orgs: channel.orgs.map((org) => ({
          name: org.name,
          peers: org.peers.map((peer) => peer.name),
        })),
      })),
      chaincodes: config.chaincodes.map((chaincode) =>
        withoutUndefined({
          name: chaincode.name,
          version: chaincode.version,
          channel: chaincode.channel.name,
          image: chaincode.image,
          endorsementPolicy: chaincode.endorsement,
          initRequired: chaincode.initRequired,
          privateData: chaincode.privateData.length > 0 ? privateDataForFabricOps(chaincode) : undefined,
          ccaas: {
            replicas: 1,
            containerPort: 7052,
            servicePort: 7052,
            dialTimeout: "10s",
            imagePullPolicy: "IfNotPresent",
          },
        }),
      ),
    }),
  }) as FabricOpsManifest;
};

const toFabricOpsYaml = (json: FabloConfigJson, config: FabloConfigExtended): string =>
  `${yaml.dump(toFabricOpsManifest(json, config), {
    lineWidth: 120,
    noRefs: true,
    sortKeys: false,
  })}`;

export { DEFAULT_FABRICNETWORK_NAME, toFabricOpsYaml };
