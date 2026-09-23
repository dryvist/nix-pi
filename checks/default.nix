# Evaluates the module inside a real Home Manager and asserts on its output.
# Nothing here builds pi: the fixtures are asserted at evaluation time, and the
# one derivation runs the generated files and the settings activation under jq.
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
        settings.defaultModel = "coder";
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

  preferred = eval [
    self.homeModules.preferences
    { programs.pi.settings.quietStartup = false; }
  ];

  # Home Manager's own module for pi writes the same directory; enabling both
  # must fail (Home Manager throws failed assertions on any config access).
  conflict = eval [ { programs.pi-coding-agent.enable = true; } ];

  expect = name: cond: lib.assertMsg cond "nix-pi check failed: ${name}";

  asserts = [
    # Bare: only the package, nothing written.
    (expect "bare installs pi" (hasPi bare))
    (expect "package = null installs nothing" (!(hasPi noPackage)))
    (expect "bare writes no files" (piFiles bare == { }))
    (expect "bare has no settings activation" (!(bare.home.activation ? piSettings)))
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
    (expect "settings.json is never linked" (!(full.home.file ? ".pi/agent/settings.json")))
    (expect "context is text" (full.home.file.".pi/agent/AGENTS.md".text == "Be brief."))
    (expect "skill dir is linked" (full.home.file.".pi/agent/skills/review".source == ./fixtures/skill))

    (expect "conflict with programs.pi-coding-agent is refused" (
      !(builtins.tryEval conflict.home.username).success
    ))

    # configDir moves every file and exports the variable pi reads.
    (expect "configDir exported" (
      movedDir.home.sessionVariables.PI_CODING_AGENT_DIR == "${home}/.config/pi"
    ))

    # Preferences apply, and one of them is overridden.
    (expect "preferences applied" (preferred.programs.pi.settings.defaultThinkingLevel == "high"))
    (expect "preferences overridable" (preferred.programs.pi.settings.quietStartup == false))
  ];

  # The activation snippet, pointed at a scratch home. The assert keeps a
  # replacement that silently stops matching from writing to the real path.
  mergeText =
    builtins.replaceStrings
      [ (lib.escapeShellArg "${home}/.pi/agent/settings.json") ]
      [ "\"$PI_TEST_HOME/.pi/agent/settings.json\"" ]
      full.home.activation.piSettings.data;
  mergeScript =
    assert expect "activation targets the scratch home" (
      lib.hasInfix "$PI_TEST_HOME" mergeText && !(lib.hasInfix home mergeText)
    );
    pkgs.writeText "pi-settings-activation" mergeText;
in
assert lib.all lib.id asserts;
{
  rendered =
    pkgs.runCommand "nix-pi-rendered"
      {
        nativeBuildInputs = [ pkgs.jq ];
      }
      ''
        # models.json keeps the key reference, never a value.
        jq -e '.providers.local.apiKey == "$LOCAL_API_KEY"' ${full.home.file.".pi/agent/models.json".source}

        run() { "$@"; }
        warnEcho() { echo "$@" >&2; }
        activate() { source ${mergeScript}; }
        export PI_TEST_HOME=$PWD/home
        target=$PI_TEST_HOME/.pi/agent/settings.json

        # No file yet: the declared keys are written.
        activate
        jq -e '. == {"defaultModel": "coder"}' "$target"

        # pi wrote its own keys and changed a declared one: declared wins, the rest stays.
        echo '{"defaultModel": "other", "theme": "light"}' > "$target"
        activate
        jq -e '. == {"defaultModel": "coder", "theme": "light"}' "$target"

        # A leftover symlink (e.g. from programs.pi-coding-agent) becomes a real file.
        rm "$target"; ln -s ${pkgs.writeText "old.json" ''{"theme":"dark"}''} "$target"
        activate
        [ ! -L "$target" ] && jq -e '.defaultModel == "coder"' "$target"

        # Broken JSON is left alone, not clobbered.
        echo '{ broken' > "$target"
        activate 2> warn
        grep -q 'not valid JSON' warn && grep -qx '{ broken' "$target"

        # Dry run writes nothing.
        echo '{}' > "$target"
        DRY_RUN=1 activate
        jq -e '. == {}' "$target"

        touch $out
      '';
}
