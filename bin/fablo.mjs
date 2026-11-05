#!/usr/bin/env node

// Entry point of the npm package: runs fablo.sh with generator commands
// executed by the local Node.js instead of the Fablo Docker image.
import { spawnSync } from "node:child_process";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const packageDir = join(dirname(fileURLToPath(import.meta.url)), "..");

const result = spawnSync("bash", [join(packageDir, "fablo.sh"), ...process.argv.slice(2)], {
  stdio: "inherit",
  env: { ...process.env, FABLO_PACKAGE_DIR: packageDir },
});

if (result.error) {
  console.error(`Error: cannot run fablo.sh with bash: ${result.error.message}`);
  process.exit(1);
}
process.exit(result.status ?? 1);
