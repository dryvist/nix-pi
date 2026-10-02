---
skill-groups: [core, nix]
---

# nix-pi - AI Agent Instructions

A Home Manager module for the pi coding agent. It follows pi's docs, and our
own choices live in one optional file.

## Rules

1. **Build nothing that exists.** The package is numtide/llm-agents.nix's `pi`,
   which is re-exported and not rebuilt. nixpkgs ships `pi-coding-agent`, and
   home-manager ships `programs.pi-coding-agent` (package, settings, models,
   keybindings, context). This flake adds only options for the agent-dir
   resources that module lacks: system prompts, skills, prompts, extensions
   and themes. Anything that belongs upstream should be proposed upstream.
2. **No scripts.** No `writeShellApplication`, activation entry or inline shell.
   Use native Nix, Home Manager and Renovate mechanisms. `settings.json` is
   not managed: pi writes it and has no layered settings file.
3. **Docs, not opinions.** Module defaults are pi's defaults.
4. **Freeform JSON.** `models` and `keybindings` follow RFC 42.
   Add an option only for a new file or directory in the agent dir.
5. **One writer for flake.lock:** `deps-flake-lock.yml` (org policy).
6. Flakes only; conventional commits; branch off `main`.

## Layout

| Path | Holds |
| --- | --- |
| `modules/pi.nix` | The `programs.pi` module |
| `upstream.nix` | The pi release the module was reconciled against (Renovate-tracked) |
| `checks/` | Home Manager fixtures with assertions |

## Validation

```bash
nix fmt
nix flake check --all-systems --no-build   # evaluates every system's outputs and assertions
```

Every behaviour gets an evaluation-time assertion in `checks/default.nix`.

## Upstream releases

Renovate bumps `upstream.nix` and opens a PR (labelled `upstream-pi`, never
auto-merged). Merge it once the module and README match the new pi release.
