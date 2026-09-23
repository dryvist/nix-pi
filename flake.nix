{
  description = "Home Manager module for the pi coding agent";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # The pi package. Not `follows`-ed onto our nixpkgs on purpose: its own pin
    # is what cache.numtide.com has built, so following ours forfeits the cache.
    llm-agents.url = "github:numtide/llm-agents.nix";

    # Used only by `checks` to evaluate the module in a real Home Manager.
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

      overlays.default = final: _prev: {
        pi-coding-agent = piFor final.stdenv.hostPlatform.system;
      };

      homeModules = {
        # The module alone. `package` defaults to nixpkgs' pi-coding-agent.
        pi = ./modules/pi.nix;

        # The module with `package` defaulting to this flake's pi.
        default =
          { lib, pkgs, ... }:
          {
            imports = [ self.homeModules.pi ];
            programs.pi.package = lib.mkDefault (
              self.packages.${pkgs.stdenv.hostPlatform.system}.pi or pkgs.pi-coding-agent
            );
          };

        # Our non-default choices, every value overridable. See ./preferences.nix.
        preferences = {
          programs.pi = lib.mapAttrsRecursive (_: lib.mkDefault) self.lib.preferences;
        };
      };

      homeManagerModules = lib.warn "nix-pi: `homeManagerModules` is renamed to `homeModules`" self.homeModules;

      lib = {
        preferences = import ./preferences.nix;
        upstream = import ./upstream.nix;
      };

      checks = forAllSystems (pkgs: import ./checks { inherit pkgs self home-manager; });

      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);
    };
}
