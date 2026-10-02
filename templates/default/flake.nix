# A Home Manager flake that installs and configures pi, the coding agent.
# Created by `nix flake init -t github:dryvist/nix-pi`. Change the values marked
# "change me", then apply it with `home-manager switch --flake .#me`.
# pi docs: https://pi.dev/docs/latest/configuration
# Home Manager docs: https://nix-community.github.io/home-manager/
{
  description = "Home Manager configuration for pi";

  inputs = {
    # The package set Home Manager builds from.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager; it provides programs.pi-coding-agent.
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs"; # one nixpkgs for both
    };

    # pi's package and the skills/prompts/system options used below.
    nix-pi = {
      url = "github:dryvist/nix-pi";
      inputs.nixpkgs.follows = "nixpkgs"; # deduplicate; pi itself keeps its own pin
      inputs.home-manager.follows = "home-manager"; # deduplicate
    };
  };

  # Pre-built pi binaries, so pi is downloaded instead of compiled.
  # Nix asks once before trusting these; see https://nix.dev/manual/nix/latest/command-ref/conf-file
  nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nix-pi,
      ...
    }:
    {
      # One user's configuration; `me` is the name passed to --flake .#me.
      homeConfigurations.me = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux; # change me: your system, e.g. aarch64-darwin

        modules = [
          # Adds the system/skills/prompts options and installs nix-pi's pi.
          nix-pi.homeModules.default

          {
            home = {
              username = "me"; # change me: your login name
              homeDirectory = "/home/me"; # change me: your home directory
              # Home Manager release this config was written for; keep it when upgrading.
              # https://nix-community.github.io/home-manager/options/home-manager/home.html#opt-home.stateVersion
              stateVersion = "26.05";
            };

            # Home Manager's options: https://nix-community.github.io/home-manager/options/home-manager/programs/pi-coding-agent.html
            # nix-pi's added options (system, skills, prompts, ...): https://github.com/dryvist/nix-pi#options
            programs.pi-coding-agent = {
              enable = true; # installs pi and writes the files below to ~/.pi/agent

              # settings.json; https://pi.dev/docs/latest/settings
              settings = {
                defaultProvider = "example"; # provider pi starts with (defined in `models`)
                defaultModel = "example-model"; # model pi starts with
              };

              # models.json, for providers pi does not know; https://pi.dev/docs/latest/models
              # Built-in providers need no entry: run `/login` or set their env var instead.
              models.providers.example = {
                baseUrl = "https://api.example.com/v1"; # change me: an OpenAI-compatible endpoint
                api = "openai-completions"; # the wire protocol that endpoint speaks
                # Read at request time from the environment. Never inline a key:
                # this file lands in the world-readable Nix store.
                # `"!cat ~/.config/example/key"` reads it from a file instead.
                apiKey = "$EXAMPLE_API_KEY";
                models = [ { id = "example-model"; } ]; # change me: the model ids it serves
              };

              # AGENTS.md: instructions loaded into every session; a path also works.
              # https://pi.dev/docs/latest/configuration
              context = ''
                Prefer small, focused changes. Run the tests before calling work done.
              '';

              # skills/: loaded when the task matches the description; https://pi.dev/docs/latest/skills
              # A path to a skill directory also works: `skills.my-skill = ./skills/my-skill;`.
              skills."commit/SKILL.md" = ''
                ---
                name: commit
                description: Write a conventional commit message. Use when committing changes.
                ---
                Summarize the staged diff as `type(scope): subject`, then a short body.
              '';

              # prompts/: each file becomes a slash command, here /review;
              # https://pi.dev/docs/latest/prompt-templates
              prompts."review.md" = ''
                ---
                description: Review staged git changes
                ---
                Review the staged changes for correctness, security and error handling.
              '';

              # SYSTEM.md replaces pi's built-in system prompt entirely; leave it
              # unset to keep pi's. https://pi.dev/docs/latest/configuration
              # system = ./SYSTEM.md;
            };
          }
        ];
      };
    };
}
