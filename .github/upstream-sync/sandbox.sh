#!/usr/bin/env bash
# Run a command where it can write only TREE and PI_CODING_AGENT_DIR.
#
# usage: sandbox.sh TREE COMMAND [ARGS...]
#
# The agent reads an untrusted upstream diff and has write/edit tools. Outside
# this sandbox those tools reach every path the runner user can, including the
# scripts this workflow runs after it. Inside, the host is read-only, /tmp is
# private, the environment is cleared except for what pi needs, and only the
# network namespace is shared (for LiteLLM). Needs unprivileged user
# namespaces on the runner.
set -euo pipefail

tree=$(realpath "$1")
shift

exec nix run nixpkgs#bubblewrap -- \
  --ro-bind / / \
  --dev /dev \
  --proc /proc \
  --tmpfs /tmp \
  --bind "$tree" "$tree" \
  --bind "$PI_CODING_AGENT_DIR" "$PI_CODING_AGENT_DIR" \
  --unshare-all --share-net \
  --die-with-parent \
  --clearenv \
  --setenv PATH "$PATH" \
  --setenv HOME /tmp \
  --setenv PI_CODING_AGENT_DIR "$PI_CODING_AGENT_DIR" \
  --setenv LITELLM_API_KEY "$LITELLM_API_KEY" \
  --chdir "$tree" \
  -- "$@"
