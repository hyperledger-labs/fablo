---
name: fablo
description: Create, validate, run, and troubleshoot local Hyperledger Fabric networks with Fablo. Use when working with fablo-config JSON or YAML, Fablo CLI commands, Docker-based Fabric networks, organizations, channels, chaincode deployment or hot reload, Fablo REST, Explorer, or network snapshots.
---

# Fablo

Fablo generates and manages Hyperledger Fabric networks from one JSON or YAML configuration. Focus on local development, CI, and experimentation; do not present generated defaults as production hardening.

## Establish context first

1. Identify the user's network working directory. Fablo uses the **current directory**, not the config file's directory, for `fablo-target` and lifecycle commands.
2. Find the executable: project-local `./fablo`, globally installed `fablo`, or `./fablo.sh` in a Fablo source checkout. Examples below use `fablo`; substitute the actual executable consistently.
3. Inspect existing `fablo-config.json` or `fablo-config.yaml`, chaincode sources, and `fablo-target` before writing or starting anything. When both default config files exist, JSON takes precedence; prefer an explicit path.
4. Check Docker availability with `docker info` and `docker compose version`. Even Fablo validation and version reporting use its Docker image and may pull images.
5. Determine whether the task is config-only, network startup, chaincode work, or diagnosis. Ask about topology and preservation of existing ledger state only when these are unclear and affect the next action.

## Safety boundaries

- Do not overwrite existing configs, chaincodes, or generated files without reviewing them.
- Before `down`, `reset`, `prune`, or `recreate`, explain the state-loss risk and obtain confirmation unless the user has already explicitly authorized that operation. Prefer `stop` and `start` for a temporary pause.
- Never use broad Docker cleanup commands to fix a single Fablo network.
- Review `hooks.postGenerate` and `hooks.postStart` before generation or startup: they execute host shell commands. Treat downloaded configs and scripts as untrusted input.
- Do not install Fablo, switch versions with `use`, or execute remote installation scripts without authorization. Prefer downloading and reviewing a pinned release over piping a URL into a shell.
- Snapshots and generated artifacts contain identities, certificates, and potentially private keys and ledger data. Do not commit or expose them. Redact credentials and private material from logs.

## Configure a network

For a new project, in an empty or reviewed working directory:

```bash
fablo init node rest
fablo validate ./fablo-config.json
```

`init` creates a starter config; `node` adds sample Node.js chaincode and `rest` enables Fablo REST. Other options include `dev` and `gateway`; inspect the installed version before combining options. Do not assume defaults or supported Fabric versions are identical across releases.

For custom topology, start from a version-compatible sample and consult the matching schema rather than inventing fields:

- `global`: Fabric version, TLS, monitoring, image overrides, peer dev mode.
- `orgs`: organization names/domains, peer counts and database choice, orderer groups, per-organization tools.
- `channels`: channel name, orderer `groupName`, participating organization names and peer names.
- `chaincodes`: name, version, channel, language, source directory or CCaaS image, endorsement policy, optional private-data collections.
- `hooks`: optional host-side commands; review before execution.

Check that channel organizations and peers exist, orderer-group references match, chaincodes reference existing channels, and source directories resolve relative to the config directory. Use `golang`, `node`, `java`, or `ccaas` for chaincode language. Validate consensus and TLS compatibility against the selected Fabric version; do not assume a sample for a different major version is compatible.

```bash
fablo validate ./fablo-config.json
fablo extend-config ./fablo-config.json
```

Resolve critical validation failures before generation. Explain warnings rather than silently ignoring them.

## Generate and manage

```bash
# Generate only; does not start the network, but may execute postGenerate.
fablo generate ./fablo-config.json

# Generate if needed, start, create channels, and deploy configured chaincodes.
fablo up ./fablo-config.json

# Temporarily pause and resume the existing network.
fablo stop
fablo start
```

Keep `fablo-target` out of version control for normal managed usage. Lifecycle commands expect it in the current working directory. If a custom generation target is explicitly needed, manage the result with its generated `fabric-docker.sh`; do not assume top-level Fablo commands will discover it.

If `up` reports that the config differs from the stored snapshot, show the difference. Do not bypass the guard by editing the stored copy. Applying a changed topology normally requires the destructive `recreate <config>` flow after confirmation and any requested backup. `reset` discards network state while retaining generated configuration; it is not a topology update.

## Chaincodes and channels

Inspect actual peer domains, channel names, chaincode names, and contract methods before forming commands. The Docker implementation uses **peer first** for invoke/query; some top-level help text has historically shown a conflicting order. Verify against the installed/generated scripts when uncertain.

```bash
fablo chaincodes install
fablo chaincode install <chaincode-name> <version>
fablo chaincode upgrade <chaincode-name> <new-version>
fablo chaincodes list <peer> <channel>

fablo chaincode query <peer-domain> <channel> <chaincode> '<JSON-command>'
fablo chaincode invoke <peer-domains-comma-separated> <channel> <chaincode> '<JSON-command>'

fablo channel --help
fablo channel list <org> <peer>
fablo channel getinfo <channel> <org> <peer>
```

Replace placeholders; never execute these literally. JSON commands use the contract's real arguments, for example `'{"Args":["Contract:method","value"]}'`. Query takes one peer; invoke can target multiple peers for endorsement. An optional transient JSON argument follows the command. Invocation writes ledger state: use it only when requested or authorized for testing.

For hot reload:

- **Peer dev mode:** `global.peerDevMode: true` with `global.tls: false`; run chaincode processes locally, one per target peer as needed.
- **CCaaS:** `lang: ccaas` with an appropriate image, `chaincodeMountPath`, and `chaincodeStartCommand`; supports TLS and per-chaincode reload setups. Review the mounted source and startup command.

Do not disable TLS as a generic troubleshooting step.

## Snapshots

```bash
fablo snapshot /safe/path/network-backup
# In an empty destination network directory:
fablo restore /safe/path/network-backup
fablo start
```

Fablo appends `.fablo.tar.gz` unless the supplied path already ends in `tar.gz`. Keep the original config and chaincode sources separately; snapshots are not a substitute for those sources. Restore only trusted snapshots into an empty destination; never silently prune a network to make room. External CCaaS containers may need `fablo chaincodes install` after restoration.

## Troubleshoot without destroying evidence

1. Capture the exact command, working directory, Fablo/Fabric versions, config path, and first meaningful error. Do not dump secrets.
2. Run config validation when relevant. Check Docker daemon access, Compose availability, image pull errors, host port collisions, and source paths.
3. Inspect `docker ps -a` and bounded `docker logs --tail 100 <affected-container>`. Inspect generated files rather than regenerating them immediately.
4. For chaincode errors, check source build/runtime failures, channel membership, endorsement requirements, and deployed version. For dev mode, verify the local process and peer address.
5. Propose the smallest targeted fix. Preserve ledger state by default; reset/recreate is a confirmed recovery choice, not a first diagnostic step.
6. Verify the requested outcome with relevant channel/chaincode queries. Report what ran, what passed, what failed, and anything not tested. Container presence alone does not prove a usable network.

## Authoritative references

When working in a Fablo checkout, resolve these paths from the repository root:

- `README.md`: user workflows and configuration overview.
- `docs/schema.json` and `samples/`: config schema and concrete topologies; match the installed release.
- `SUPPORTED_FEATURES.md`: support and compatibility notes.
- `fablo.sh`: wrapper behavior, working-directory rules, and config-change guard.
- `src/setup-docker/templates/fabric-docker/chaincode-scripts.sh`: invoke/query argument order.
- `src/setup-docker/templates/fabric-docker.sh`: generated command dispatch.

Outside a checkout, use [Fablo documentation](https://github.com/hyperledger-labs/fablo#readme), [samples](https://github.com/hyperledger-labs/fablo/tree/main/samples), and the schema for the installed release. Prefer installed code and release-specific documentation over examples from another version. Do not assume optional integrations such as an MCP server are installed.
