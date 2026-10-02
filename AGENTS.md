---
skill-groups: [core, nix]
---

# nix-pi - AI Agent Instructions

The numtide/llm-agents.nix build of pi, plus Home Manager options that
Home Manager's `programs.pi-coding-agent` module lacks.

## Rules

1. **Build nothing that exists.** The package is numtide/llm-agents.nix's `pi`,
   re-exported, not rebuilt. Home Manager's `programs.pi-coding-agent` owns
   the package, `settings`, `models`, `keybindings`, `context`,
   `appendSystem`, `configDir` and `extraPackages`; this flake only adds
   options to that namespace for agent-dir files it does not write
   (`SYSTEM.md`, skills, prompts, extensions, themes). Drop an option here
   once Home Manager ships it.
2. **No scripts.** No `writeShellApplication`, activation entry or inline shell.
   Use native Nix, Home Manager and Renovate mechanisms.
3. **Docs, not opinions.** Module defaults are pi's defaults.
4. **One writer for flake.lock:** `deps-flake-lock.yml` (org policy).
5. Flakes only; conventional commits; branch off `main`.

## Layout

| Path | Holds |
| --- | --- |
| `modules/pi.nix` | Options added to `programs.pi-coding-agent` |
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
