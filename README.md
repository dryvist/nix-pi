# nix-pi

A reference Nix setup for [pi](https://pi.dev), the coding agent: a Home
Manager flake template to copy, plus a few Home Manager options for the pi
files Home Manager does not manage yet.

## Quick start

Start a new configuration from the template:

```sh
nix flake init -t github:dryvist/nix-pi
```

Change the values marked `change me` in `flake.nix`, then apply it with
`home-manager switch --flake .#me`. Each setting in the template is commented
and links to the pi or Home Manager docs it uses.

Or add the module to an existing Home Manager flake:

```nix
{
  inputs.nix-pi.url = "github:dryvist/nix-pi";
  # then add inputs.nix-pi.homeModules.default to your Home Manager modules
}
```

To try pi without installing anything: `nix run github:dryvist/nix-pi`.

## Options

Home Manager's
[`programs.pi-coding-agent`](https://nix-community.github.io/home-manager/options/home-manager/programs/pi-coding-agent.html)
writes `settings.json`, `models.json`, `keybindings.json` and `AGENTS.md`.
This flake adds options to the same namespace for the other
[files pi reads](https://pi.dev/docs/latest/configuration) from its agent
directory:

| Option | Writes | pi docs |
| --- | --- | --- |
| `system` | `SYSTEM.md`, replacing pi's system prompt | [configuration](https://pi.dev/docs/latest/configuration) |
| `skills.<path>` | `skills/<path>` | [skills](https://pi.dev/docs/latest/skills) |
| `prompts.<path>` | `prompts/<path>`, one slash command per file | [prompt templates](https://pi.dev/docs/latest/prompt-templates) |
| `extensions.<path>` | `extensions/<path>` | [extensions](https://pi.dev/docs/latest/extensions) |
| `themes.<path>` | `themes/<path>` | [themes](https://pi.dev/docs/latest/themes) |

Each value is text or a path to a file or directory. Files go under
`programs.pi-coding-agent.configDir`.

`homeModules.default` also sets `programs.pi-coding-agent.package` to this
flake's pi. `homeModules.pi-coding-agent` adds only the options and keeps
nixpkgs' `pi-coding-agent`.

## Why it is set up this way

- **Pre-built package.** pi comes from
  [numtide/llm-agents.nix](https://github.com/numtide/llm-agents.nix), which
  tracks pi releases and publishes binaries to its cache. That input keeps its
  own nixpkgs, so the cache matches and pi is downloaded instead of compiled.
- **Home Manager first.** Use the upstream `programs.pi-coding-agent` options
  wherever they exist; this flake only fills the gaps, and drops an option once
  Home Manager ships it.
- **No scripts.** Everything is plain Home Manager file declarations: no
  activation scripts or wrappers.
- **Read-only files.** Each file is linked from the Nix store, so the
  configuration is the only place it changes, and rollbacks restore it.
- **No secrets in Nix.** The store is world-readable; API keys are read at
  run time from an environment variable or a command.

## Staying current

Your `flake.lock` pins pi, Home Manager and nixpkgs. Update them together with
`nix flake update`, then switch.

## Contributing

The `.github` workflows, `renovate.json` and `AGENTS.md` maintain this
repository's CI; they are not part of the template. See [AGENTS.md](AGENTS.md).
