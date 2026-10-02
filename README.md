# nix-pi

[pi](https://pi.dev) (the coding agent) for Nix: the
[numtide/llm-agents.nix](https://github.com/numtide/llm-agents.nix) build of pi,
and Home Manager options for the agent-dir files that Home Manager's own
`programs.pi-coding-agent` module does not manage.

## Installation

Try it without installing:

```sh
nix run github:dryvist/nix-pi
```

Or add it to your Home Manager flake:

```nix
{
  inputs.nix-pi.url = "github:dryvist/nix-pi";

  # in your homeManagerConfiguration modules:
  #   inputs.nix-pi.homeModules.default
}
```

`homeModules.default` sets `programs.pi-coding-agent.package` to this flake's
pi. `homeModules.pi-coding-agent` adds only the options below and keeps
nixpkgs' `pi-coding-agent`.

## Usage

Home Manager's `programs.pi-coding-agent` covers `settings`, `models`,
`keybindings`, `context` (`AGENTS.md`), `appendSystem`, `configDir` and
`extraPackages`. This flake adds:

```nix
programs.pi-coding-agent = {
  enable = true;
  system = ./SYSTEM.md;               # replaces pi's system prompt
  skills.review = ./skills/review;    # skills/review
  prompts."review.md" = "Review this."; # prompts/review.md
  extensions."hello.ts" = ./hello.ts; # extensions/hello.ts
  themes."my-theme.json" = ./my-theme.json; # themes/my-theme.json
};
```

Each writes the file pi documents in
[its configuration docs](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/configuration.md),
under `programs.pi-coding-agent.configDir`.

## Contributing

See [AGENTS.md](AGENTS.md).
