#!/usr/bin/env bash
set -euo pipefail

# Prints mcp/skill.jh: the Fablo skill as a Jaiph constant, so the MCP server
# needs no skill file at run time. After changing the skill, run:
#   bash mcp/embed-skill.sh > mcp/skill.jh
skill="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/skills/fablo/SKILL.md"

echo '# Generated from skills/fablo/SKILL.md by mcp/embed-skill.sh. Do not edit.'
echo 'const skill = """'
cat "$skill"
echo '"""'
echo
echo '# The Fablo skill text, for prompts.'
echo 'export def text() {'
echo '  return skill'
echo '}'
