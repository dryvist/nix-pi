# nix-pi

[pi](https://pi.dev) (the coding agent) for Nix. Home Manager writes pi's
config files, and pi keeps full control of its own `settings.json`.

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

## Usage

```nix
programs.pi = {
  enable = true;
  models.providers.local = {
    baseUrl = "http://127.0.0.1:8080/v1";
    api = "openai-completions";
    apiKey = "$LOCAL_API_KEY"; # read from the environment when pi runs
    models = [ { id = "qwen3-coder"; } ];
  };
};
```

Each option writes one of the files in
[pi's docs](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/configuration.md):
`models`, `keybindings`, `context` (`AGENTS.md`), `systemPrompt`,
`appendSystemPrompt`, `skills`, `prompts`, `extensions` and `themes`.

`settings.json` is not managed: pi has no layered or read-only settings file,
and it rewrites that file itself (`/settings`, `pi install`).

## Contributing

See [AGENTS.md](AGENTS.md).
