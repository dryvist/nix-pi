# Evaluates the module inside a real Home Manager and asserts on its output.
# Every assertion is evaluated; nothing builds pi.
{
  pkgs,
  self,
  home-manager,
}:
let
  inherit (pkgs) lib;
  home = "/pi-test-home";

  eval =
    modules:
    (home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        self.homeModules.default
        {
          home = {
            username = "pi-test";
            homeDirectory = home;
            stateVersion = "26.05";
          };
          programs.pi.enable = true;
        }
      ]
      ++ modules;
    }).config;

  piFiles = config: lib.filterAttrs (name: _: lib.hasPrefix ".pi/" name) config.home.file;

  hasPi = config: builtins.elem "pi" (map lib.getName config.home.packages);

  bare = eval [ ];
  noPackage = eval [ { programs.pi.package = null; } ];

  full = eval [
    {
      programs.pi = {
        models.providers.local = {
          baseUrl = "http://127.0.0.1:8080/v1";
          api = "openai-completions";
          apiKey = "$LOCAL_API_KEY";
          models = [ { id = "coder"; } ];
        };
        keybindings."app.model.select" = "ctrl+l";
        context = "Be brief.";
        systemPrompt = ./fixtures/SYSTEM.md;
        appendSystemPrompt = "Cite files.";
        skills.review = ./fixtures/skill;
        prompts."review.md" = "Review this.";
        extensions."hello.ts" = ./fixtures/hello.ts;
        themes."plain.json" = ./fixtures/plain.json;
      };
    }
  ];

  movedDir = eval [ { programs.pi.configDir = ".config/pi"; } ];

  # Home Manager's own module for pi writes the same directory; enabling both
  # must fail (Home Manager throws failed assertions on any config access).
  conflict = eval [ { programs.pi-coding-agent.enable = true; } ];

  expect = name: cond: lib.assertMsg cond "nix-pi check failed: ${name}";

  asserts = [
    # Bare: only the package, nothing written.
    (expect "bare installs pi" (hasPi bare))
    (expect "package = null installs nothing" (!(hasPi noPackage)))
    (expect "bare writes no files" (piFiles bare == { }))
    (expect "bare leaves PI_CODING_AGENT_DIR unset" (
      !(bare.home.sessionVariables ? PI_CODING_AGENT_DIR)
    ))

    # Full: every option lands at the path pi documents.
    (expect "full file set" (
      builtins.attrNames (piFiles full) == [
        ".pi/agent/AGENTS.md"
        ".pi/agent/APPEND_SYSTEM.md"
        ".pi/agent/SYSTEM.md"
        ".pi/agent/extensions/hello.ts"
        ".pi/agent/keybindings.json"
        ".pi/agent/models.json"
        ".pi/agent/prompts/review.md"
        ".pi/agent/skills/review"
        ".pi/agent/themes/plain.json"
      ]
    ))
    (expect "settings.json is left to pi" (!(full.home.file ? ".pi/agent/settings.json")))
    (expect "no pi activation entry" (!(full.home.activation ? piSettings)))
    (expect "context is text" (full.home.file.".pi/agent/AGENTS.md".text == "Be brief."))
    (expect "skill dir is linked" (full.home.file.".pi/agent/skills/review".source == ./fixtures/skill))

    (expect "conflict with programs.pi-coding-agent is refused" (
      !(builtins.tryEval conflict.home.username).success
    ))

    # configDir moves every file and exports the variable pi reads.
    (expect "configDir exported" (
      movedDir.home.sessionVariables.PI_CODING_AGENT_DIR == "${home}/.config/pi"
    ))
  ];
in
assert lib.all lib.id asserts;
{
  # Evaluation-time assertions only; a trivial derivation carries them into `nix flake check`.
  module = pkgs.emptyFile;
}
