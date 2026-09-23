# Home Manager module for pi. Every file here is one pi documents; see
# https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/configuration.md
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.pi;
  json = pkgs.formats.json { };
  docs = page: "https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/${page}";

  agentDir = "${config.home.homeDirectory}/${cfg.configDir}";
  settingsFile = json.generate "pi-settings.json" cfg.settings;

  textOrPath = lib.types.either lib.types.lines lib.types.path;

  # A file pi reads but never writes: link it from the store.
  fileFrom =
    value:
    if builtins.isPath value || lib.isStorePath value then { source = value; } else { text = value; };

  jsonOption =
    file: page:
    lib.mkOption {
      inherit (json) type;
      default = { };
      description = "Contents of `${file}`. See ${docs page}.";
    };

  textOption =
    file: page:
    lib.mkOption {
      type = lib.types.nullOr textOrPath;
      default = null;
      description = "Contents of `${file}`, as text or a path. See ${docs page}.";
    };

  resourceOption =
    dir: page: example:
    lib.mkOption {
      type = lib.types.attrsOf textOrPath;
      default = { };
      example = lib.literalExpression example;
      description = ''
        Entries placed under `${dir}/`, keyed by their path there. A path value
        (file or directory) is linked; a string is written as a file.
        See ${docs page}.
      '';
    };

  # Option name == directory name under the agent dir.
  resourceDirs = [
    "skills"
    "prompts"
    "extensions"
    "themes"
  ];
in
{
  options.programs.pi = {
    enable = lib.mkEnableOption "the pi coding agent";

    package = lib.mkPackageOption pkgs "pi-coding-agent" { nullable = true; };

    configDir = lib.mkOption {
      type = lib.types.str;
      default = ".pi/agent";
      description = ''
        Agent directory, relative to the home directory. A value other than the
        default is exported as `PI_CODING_AGENT_DIR`.
      '';
    };

    settings = lib.mkOption {
      inherit (json) type;
      default = { };
      example = {
        defaultThinkingLevel = "high";
        quietStartup = true;
      };
      description = ''
        Keys for `settings.json`. See ${docs "settings.md"}.

        pi writes this file itself (`/settings`, `pi install`), so it is merged,
        not linked: on each activation these keys overwrite the same keys in
        the existing file and every other key is kept. A key removed here is
        not removed from the file.
      '';
    };

    models = jsonOption "models.json" "models.md";
    keybindings = jsonOption "keybindings.json" "keybindings.md";

    context = textOption "AGENTS.md" "configuration.md";
    systemPrompt = textOption "SYSTEM.md" "configuration.md";
    appendSystemPrompt = textOption "APPEND_SYSTEM.md" "configuration.md";

    skills = resourceOption "skills" "skills.md" "{ review = ./skills/review; }";
    prompts = resourceOption "prompts" "prompt-templates.md" ''{ "review.md" = ./review.md; }'';
    extensions = resourceOption "extensions" "extensions.md" ''{ "hello.ts" = ./hello.ts; }'';
    themes = resourceOption "themes" "themes.md" ''{ "my-theme.json" = ./my-theme.json; }'';
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !(config.programs.pi-coding-agent.enable or false);
        message = "programs.pi and programs.pi-coding-agent both manage pi's agent directory; enable one.";
      }
    ];

    home = {
      packages = lib.optional (cfg.package != null) cfg.package;

      sessionVariables = lib.mkIf (cfg.configDir != ".pi/agent") {
        PI_CODING_AGENT_DIR = agentDir;
      };

      file =
        let
          at = name: "${cfg.configDir}/${name}";
          jsonFile =
            name: value:
            lib.optionalAttrs (value != { }) { ${at name}.source = json.generate "pi-${name}" value; };
          textFile = name: value: lib.optionalAttrs (value != null) { ${at name} = fileFrom value; };
          resources = lib.mergeAttrsList (
            map (
              dir:
              lib.mapAttrs' (name: value: lib.nameValuePair (at "${dir}/${name}") (fileFrom value)) cfg.${dir}
            ) resourceDirs
          );
        in
        jsonFile "models.json" cfg.models
        // jsonFile "keybindings.json" cfg.keybindings
        // textFile "AGENTS.md" cfg.context
        // textFile "SYSTEM.md" cfg.systemPrompt
        // textFile "APPEND_SYSTEM.md" cfg.appendSystemPrompt
        // resources;

      activation.piSettings = lib.mkIf (cfg.settings != { }) (
        lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          target=${lib.escapeShellArg "${agentDir}/settings.json"}
          run mkdir -p "$(dirname "$target")"
          if [ -L "$target" ]; then run rm "$target"; fi
          if [ -s "$target" ]; then
            if merged=$(${lib.getExe pkgs.jq} -s '.[0] * .[1]' "$target" ${settingsFile}); then
              [ -v DRY_RUN ] || printf '%s\n' "$merged" > "$target"
            else
              warnEcho "pi: $target is not valid JSON; left unchanged"
            fi
          else
            run install -m 644 ${settingsFile} "$target"
          fi
        ''
      );
    };
  };
}
