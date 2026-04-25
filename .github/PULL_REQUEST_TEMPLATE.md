## Description

Please include a summary of the change and which issue is fixed. Include relevant motivation, context, and any dependencies required.

Fixes # (issue)

## Type of Change

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update only
- [ ] Refactor / code quality improvement (no behavior change)

## What Does This Change?

> Check all that apply and briefly describe what changed in each area:

- [ ] **Config schema** (`src/types/`, `docs/schema.json`) — added/changed a config field
- [ ] **Config enrichment** (`src/extend-config/`) — changed how config values are derived
- [ ] **EJS templates** (`src/setup-docker/templates/`) — changed generated file output
- [ ] **CLI commands** (`src/commands/`) — added or modified a command
- [ ] **Hooks** (`hooks/post-generate.sh`, `hooks/post-start.sh`) — changed lifecycle behavior
- [ ] **Scripts / Docker Compose** (`fabric-docker/`, `fabric-config/`) — changed network setup
- [ ] **Tests** (`e2e/`, `e2e-network/`) — added or updated tests
- [ ] **Documentation** (`README.md`, `SUPPORTED_FEATURES.md`, `ARCHITECTURE.md`)

## Sample Config Snippet

> If this PR adds or changes a feature, paste a minimal `fablo-config.json` snippet that demonstrates it.
> This helps reviewers and users understand the change quickly without reading all the code.
> Delete this section if not applicable.

```json
{
  "global": { "fabricVersion": "2.5.0", "tls": false },
  "orgs": [...],
  ...
}
```

## New or Changed Config Fields

> If you added or changed any fields in `fablo-config.json`, fill in this table. Delete if not applicable.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `example.field` | `string` | No | `"value"` | What it does |

## Breaking Changes & Migration Guide

> If this is a breaking change, describe **what breaks** and **how existing users migrate**.
> Delete this section if not applicable.

**What breaks:**
<!-- e.g. "The `peer.db` field is renamed to `peer.database`" -->

**How to migrate:**
```json
// Before
{ "peer": { "db": "CouchDb" } }

// After
{ "peer": { "database": "CouchDb" } }
```

## Network Behavior Impact

> Does this change affect how the Fabric network starts up, its timing, or error behavior?
> This is especially important for changes to `commands-generated.sh`, `base-functions.sh`, or Docker Compose.
> Delete this section if not applicable.

- [ ] No impact on network startup / runtime behavior
- [ ] Startup time improved — briefly explain: 
- [ ] Startup time increased — briefly explain and justify: 
- [ ] Error handling improved — briefly explain: 

## Fabric Versions Tested

- [ ] Fabric 2.x (e.g. `2.5.x`)
- [ ] Fabric 3.x (e.g. `3.0.x`)
- [ ] Both

## How Has This Been Tested?

Please describe the tests you ran and provide steps to reproduce locally.

- [ ] Unit tests — `npm run test:unit`
- [ ] E2E snapshot tests — `npm run test:e2e`
- [ ] Snapshots updated (required if any EJS template changed) — `npm run test:e2e-update`
- [ ] E2E network tests — shell scripts in `e2e-network/` directory

**Steps to reproduce / verify this change manually:**
```bash
# 1. Build local image
./fablo-build.sh

# 2. Run with sample config
./fablo.sh up samples/your-sample.json
```

## For Reviewers

> Point reviewers to the most important files to look at, in priority order.
> Delete this section if the diff is small and self-explanatory.

1. `src/...` — core logic change, start here
2. `e2e/__snapshots__/...` — verify output looks correct
3. `samples/...` — check the example reflects the feature correctly

## Checklist

- [ ] I have signed off my commits with `git commit -s` (required — DCO)
- [ ] My code follows the style guidelines of this project (`npm run lint`)
- [ ] I have self-reviewed my own code and the generated diff
- [ ] I have commented hard-to-understand areas of code
- [ ] If I added/changed a config field: the JSON Schema (`docs/schema.json`) is updated
- [ ] If I added/changed a config field: at least one sample in `samples/` reflects the change
- [ ] If I changed an EJS template: snapshots in `e2e/__snapshots__/` are updated
- [ ] My changes generate no new warnings or linting errors
- [ ] I have updated relevant documentation (`README.md`, `SUPPORTED_FEATURES.md`, etc.)
