---
skill-groups: [core, nix]
---

# nix-pi - AI Agent Instructions

A reference Home Manager template for pi (`templates/default`), the
numtide/llm-agents.nix build of pi, and Home Manager options that
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
4. **The template is for anyone.** Each setting commented and linked to its docs; no
   values specific to any environment; no API keys inline; none of this
   repository's maintainer files (`.github`, `renovate.json`, `AGENTS.md`).
5. **One version source.** pi's version is the `llm-agents` input in
   `flake.lock`; its only writer is `deps-flake-lock.yml` (org policy).
6. Flakes only; conventional commits; branch off `main`.

## Layout

| Path | Holds |
| --- | --- |
| `modules/pi.nix` | Options added to `programs.pi-coding-agent` |
| `templates/default/` | The `nix flake init -t` template |
| `checks/` | Home Manager fixtures and the template, with assertions |

## Validation

```bash
nix fmt
nix flake check --all-systems   # evaluates every system's outputs and assertions
```

Every behaviour gets an evaluation-time assertion in `checks/default.nix`.
