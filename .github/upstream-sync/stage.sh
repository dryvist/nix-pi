#!/usr/bin/env bash
# Stage the agent's work, refusing any change outside AGENT_PATHS (and the
# WORK scratch directory). Called by upstream-sync.yml with both in the env.
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
git add -A -- . ":!$WORK"
