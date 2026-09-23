# nix-pi

[pi](https://pi.dev) (the coding agent) for Nix. Home Manager writes pi's
config files, and pi is still free to edit its own settings.

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
  settings.defaultThinkingLevel = "high";
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
`settings`, `models`, `keybindings`, `context` (`AGENTS.md`), `systemPrompt`,
`appendSystemPrompt`, `skills`, `prompts`, `extensions` and `themes`.

`settings.json` is merged rather than linked. On each switch, the keys you set
replace the same keys in the file, and anything pi wrote itself stays.

To use our preferences as well, import `inputs.nix-pi.homeModules.preferences`.
They are listed in [`preferences.nix`](preferences.nix), and you can override
any of them.

## Contributing

See [AGENTS.md](AGENTS.md).
