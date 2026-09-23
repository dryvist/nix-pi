#!/usr/bin/env bash
# Publish the agent's work: a pi-sync PR, or a note on the Renovate PR when
# nothing needed changing. Called by upstream-sync.yml with GH_TOKEN (the App
# token), FROM, TO, CHANGED, CHECK, SUMMARY (the agent's report), RENOVATE_PR
# (empty on dispatch) and BASE_REF in the environment.
set -euo pipefail

bot="nix-pi upstream sync"
body=$RUNNER_TEMP/body.md
remote="https://x-access-token:${GH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

if [ "$CHANGED" != "true" ]; then
  { cat "$SUMMARY"; echo; echo "No module changes needed; the version bump can merge as is."; } > "$body"
  [ -z "$RENOVATE_PR" ] || gh pr comment "$RENOVATE_PR" --body-file "$body"
  gh workflow run deps-flake-lock.yml
  exit 0
fi

branch="pi-sync/v$TO"

# Re-runs replace the bot's own branch, never one a person has pushed to.
existing=$(git ls-remote "$remote" "refs/heads/$branch" | cut -f1)
if [ -n "$existing" ]; then
  git fetch -q --depth=1 "$remote" "$existing"
  author=$(git log -1 --format=%an "$existing")
  if [ "$author" != "$bot" ]; then
    msg="\`$branch\` has commits from $author; left untouched. Delete the branch to let upstream sync regenerate it."
    echo "::warning::$msg"
    [ -z "$RENOVATE_PR" ] || gh pr comment "$RENOVATE_PR" --body "$msg"
    exit 0
  fi
fi

git config user.name "$bot"
git config user.email "github-actions[bot]@users.noreply.github.com"
git switch -c "$branch"
git commit -m "feat(pi): reconcile module with pi $TO"
# The lease also refuses a push that lands between the check above and now.
git push --force-with-lease="refs/heads/$branch:$existing" "$remote" "HEAD:refs/heads/$branch"

{
  cat "$SUMMARY"
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
