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
  agentDir = "${home}/.pi/agent";

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
          programs.pi-coding-agent.enable = true;
        }
      ]
      ++ modules;
    }).config;

  filesUnder = dir: config: lib.filterAttrs (name: _: lib.hasPrefix "${dir}/" name) config.home.file;

  piPackages = config: lib.filter (p: lib.getName p == "pi") config.home.packages;

  bare = eval [ ];

  full = eval [
    {
      programs.pi-coding-agent = {
        system = ./fixtures/SYSTEM.md;
        skills.review = ./fixtures/skill;
        prompts."review.md" = "Review this.";
        extensions."hello.ts" = ./fixtures/hello.ts;
        themes."plain.json" = ./fixtures/plain.json;
      };
    }
  ];

  movedDir = eval [
    {
      programs.pi-coding-agent = {
        configDir = "${home}/.config/pi";
        system = "Be brief.";
      };
    }
  ];

  expect = name: cond: lib.assertMsg cond "nix-pi check failed: ${name}";

  asserts = [
    # Bare: only this flake's pi, nothing written.
    (expect "bare installs this flake's pi" (
      map (p: p.outPath) (piPackages bare)
      == [ self.packages.${pkgs.stdenv.hostPlatform.system}.pi.outPath ]
    ))
    (expect "bare writes no files" (filesUnder agentDir bare == { }))

    # Full: every option lands at the path pi documents.
    (expect "full file set" (
      builtins.attrNames (filesUnder agentDir full) == map (f: "${agentDir}/${f}") [
        "SYSTEM.md"
        "extensions/hello.ts"
        "prompts/review.md"
        "skills/review"
        "themes/plain.json"
      ]
    ))
    (expect "prompt is text" (full.home.file."${agentDir}/prompts/review.md".text == "Review this."))
    (expect "skill dir is linked" (
      full.home.file."${agentDir}/skills/review".source == ./fixtures/skill
    ))

    # Files follow Home Manager's configDir.
    (expect "configDir moves files" (
      builtins.attrNames (filesUnder "${home}/.config/pi" movedDir) == [ "${home}/.config/pi/SYSTEM.md" ]
    ))
  ];
in
assert lib.all lib.id asserts;
{
  # Evaluation-time assertions only; a trivial derivation carries them into `nix flake check`.
  module = pkgs.emptyFile;
}
