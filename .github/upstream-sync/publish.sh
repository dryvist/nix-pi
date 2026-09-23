#!/usr/bin/env bash
# Publish the agent's work: a pi-sync PR, or a note on the Renovate PR when
# nothing needed changing. Called by upstream-sync.yml with GH_TOKEN (the App
# token), FROM, TO, CHANGED, CHECK, RENOVATE_PR (empty on dispatch), BASE_REF
# and WORK in the environment.
set -euo pipefail

body=$RUNNER_TEMP/body.md

if [ "$CHANGED" != "true" ]; then
  { cat "$WORK/SUMMARY.md"; echo; echo "No module changes needed; the version bump can merge as is."; } > "$body"
  [ -z "$RENOVATE_PR" ] || gh pr comment "$RENOVATE_PR" --body-file "$body"
  gh workflow run deps-flake-lock.yml
  exit 0
fi

branch="pi-sync/v$TO"
git config user.name "nix-pi upstream sync"
git config user.email "github-actions[bot]@users.noreply.github.com"
git switch -c "$branch"
git commit -m "feat(pi): reconcile module with pi $TO"
git push --force "https://x-access-token:${GH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" "HEAD:refs/heads/$branch"

{
  cat "$WORK/SUMMARY.md"
  echo
  echo "---"
  echo "Written by pi $TO through the homelab LiteLLM from the diff of the $FROM and $TO npm releases."
  echo "\`nix flake check\` against the latest llm-agents: **${CHECK}**. flake.lock is relocked separately."
  [ -z "$RENOVATE_PR" ] || echo "Supersedes #$RENOVATE_PR (includes its commit)."
} > "$body"

labels=upstream-pi
[ "$CHECK" = "passed" ] || labels="$labels,needs-human"
if [ "$(gh pr view "$branch" --json state -q .state 2>/dev/null || true)" = "OPEN" ]; then
  gh pr edit "$branch" --body-file "$body" --add-label "$labels"
else
  gh pr create --base "$BASE_REF" --head "$branch" \
    --title "feat(pi): reconcile with pi $TO" --body-file "$body" --label "$labels"
fi
[ -z "$RENOVATE_PR" ] || gh pr comment "$RENOVATE_PR" --body "Reconciled in $(gh pr view "$branch" --json url -q .url)."
gh workflow run deps-flake-lock.yml
