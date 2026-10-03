{
  description = "Template and Home Manager options for pi, the coding agent";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # The pi package. Not `follows`-ed onto our nixpkgs on purpose: its own pin
    # is what cache.numtide.com has built, so following ours forfeits the cache.
    llm-agents.url = "github:numtide/llm-agents.nix";

    # Used only by `checks` to evaluate the module and template in a real Home Manager.
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  outputs =
    {
      self,
      nixpkgs,
      llm-agents,
      home-manager,
    }:
    let
      inherit (nixpkgs) lib;

      # Every system llm-agents builds pi for.
      systems = builtins.attrNames llm-agents.packages;
      forAllSystems = f: lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      piFor = system: llm-agents.packages.${system}.pi;
    in
    {
      packages = forAllSystems (pkgs: rec {
        pi = piFor pkgs.stdenv.hostPlatform.system;
        default = pi;
      });

      homeModules = {
        # Home Manager's programs.pi-coding-agent gains options for the agent-dir
        # files it does not manage. Its `package` stays nixpkgs' pi-coding-agent.
        pi-coding-agent.imports = [ ./modules/pi.nix ];

        # The same, with `package` defaulting to this flake's pi.
        default =
          { lib, pkgs, ... }:
          {
            imports = [ self.homeModules.pi-coding-agent ];
            programs.pi-coding-agent.package = lib.mkDefault (
              self.packages.${pkgs.stdenv.hostPlatform.system}.pi or pkgs.pi-coding-agent
            );
          };
      };

      # A Home Manager flake to start from: `nix flake init -t github:dryvist/nix-pi`.
      templates.default = {
        path = ./templates/default;
        description = "Home Manager configuration for pi";
      };

      # Evaluates the module and the template in a real Home Manager.
      checks = forAllSystems (
        pkgs:
        import ./checks {
          inherit
            pkgs
            self
            nixpkgs
            home-manager
            ;
        }
      );

      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);
    };
}
