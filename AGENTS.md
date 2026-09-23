---
skill-groups: [core, nix]
---

# nix-pi - AI Agent Instructions

A Home Manager module for the pi coding agent. It follows pi's docs, and our
own choices live in one optional file.

## Rules

1. **Build nothing that exists.** The package is numtide/llm-agents.nix's `pi`,
   which is re-exported and not rebuilt. nixpkgs ships `pi-coding-agent`, and
   home-manager ships `programs.pi-coding-agent`. This flake adds only what
   those lack: a merged `settings.json`, options for every agent-dir resource,
   and the upstream sync. Anything that belongs upstream should be proposed
   upstream.
2. **Docs, not opinions.** Module defaults are pi's defaults. Any deviation
   goes in `preferences.nix`, applied only through `homeModules.preferences`.
3. **Freeform JSON.** `settings`, `models` and `keybindings` follow RFC 42.
   Add an option only for a new file or directory in the agent dir.
4. **One writer for flake.lock:** `deps-flake-lock.yml` (org policy).
5. Flakes only; conventional commits; branch off `main`.

## Layout

| Path | Holds |
| --- | --- |
| `modules/pi.nix` | The `programs.pi` module |
| `preferences.nix` | Our non-default values (opt-in) |
| `upstream.nix` | The pi release the module was reconciled against (Renovate-tracked) |
| `checks/` | Home Manager fixtures with assertions, plus the settings-merge test |
| `.github/upstream-sync/` | Release diff, agent prompt and publish script |

## Validation

```bash
nix fmt
nix flake check
# every system's assertions, no builds (what CI's all-systems job runs):
nix eval --raw .#checks --apply 'cs: builtins.concatStringsSep "\n"
  (builtins.concatMap (s: map (c: c.drvPath) (builtins.attrValues s)) (builtins.attrValues cs))'
```

Every behaviour gets an assertion in `checks/default.nix`.

## Upstream sync

1. Renovate bumps `upstream.nix`.
2. [`upstream-sync.yml`](.github/workflows/upstream-sync.yml) diffs the two npm
   releases. The new pi reads that diff through the homelab LiteLLM, on a
   self-hosted runner, and edits the module.
3. The job opens a `pi-sync/v<version>` PR, or comments on the Renovate PR if
   nothing needed changing.

The trust boundary and the one-time setup (runner labels, variables and
secrets) are documented in that workflow's header.
