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
   those lack: a merged `settings.json` and options for every agent-dir
   resource. Anything that belongs upstream should be proposed upstream.
2. **No custom scripts.** Use native Nix, Home Manager and Renovate mechanisms.
   The one script is `modules/merge-settings.nix`: Home Manager has no option
   for a file the program also writes.
3. **Docs, not opinions.** Module defaults are pi's defaults. Any deviation
   goes in `preferences.nix`, applied only through `homeModules.preferences`.
4. **Freeform JSON.** `settings`, `models` and `keybindings` follow RFC 42.
   Add an option only for a new file or directory in the agent dir.
5. **One writer for flake.lock:** `deps-flake-lock.yml` (org policy).
6. Flakes only; conventional commits; branch off `main`.

## Layout

| Path | Holds |
| --- | --- |
| `modules/pi.nix` | The `programs.pi` module |
| `modules/merge-settings.nix` | The `settings.json` merge script |
| `preferences.nix` | Our non-default values (opt-in) |
| `upstream.nix` | The pi release the module was reconciled against (Renovate-tracked) |
| `checks/` | Home Manager fixtures with assertions, plus the settings-merge test |

## Validation

```bash
nix fmt
nix flake check --all-systems --no-build   # evaluates every system's outputs and assertions
nix build .#checks.<your-system>.settings-merge
```

Every behaviour gets an assertion in `checks/default.nix`.

## Upstream releases

Renovate bumps `upstream.nix` and opens a PR (labelled `upstream-pi`, never
auto-merged). Merge it once the module and README match the new pi release.
