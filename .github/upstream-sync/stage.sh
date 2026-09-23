#!/usr/bin/env bash
# Stage the agent's work (applied from its patch), refusing any change outside
# AGENT_PATHS or the WORK scratch directory, and any symlink. Called by
# upstream-sync.yml with both in the env.
set -euo pipefail

read -ra allowed <<< "$AGENT_PATHS"

outside=$(
  git status --porcelain=v1 -z --untracked-files=all -- . ":!$WORK" "${allowed[@]/#/:!}" |
    tr '\0' '\n' | grep -v '^$' | cut -c4- || true
)
if [ -n "$outside" ]; then
  echo "::error::Changes outside the agent's editable paths ($AGENT_PATHS); nothing is published:"
  printf '%s\n' "$outside"
  exit 1
fi

# Everything that changed is inside the allowlist now.
git add -A -- .

# A symlink inside the allowlist could point anywhere; the agent has no use
# for one.
links=$(git diff --cached --diff-filter=AMT --raw | awk '$2 == "120000" {print $6}')
if [ -n "$links" ]; then
  echo "::error::The agent's changes add symlinks; nothing is published:"
  printf '%s\n' "$links"
  exit 1
fi
