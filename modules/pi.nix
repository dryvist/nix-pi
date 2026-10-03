# Adds to Home Manager's programs.pi-coding-agent the agent-dir files it does
# not manage. Every file here is one pi documents; see
# https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/configuration.md
{
  config,
  lib,
  ...
}:
let
  cfg = config.programs.pi-coding-agent;
  docs = page: "https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/${page}";

  textOrPath = lib.types.either lib.types.lines lib.types.path;

  # A file pi reads but never writes: link it from the store.
  fileFrom =
    value:
    if builtins.isPath value || lib.isStorePath value then { source = value; } else { text = value; };

  resourceOption =
    dir: page: example:
    lib.mkOption {
      type = lib.types.attrsOf textOrPath;
      default = { };
      example = lib.literalExpression example;
      description = ''
        Entries placed under `${dir}/` in
        {option}`programs.pi-coding-agent.configDir`, keyed by their path
        there. A path value (file or directory) is linked; a string is
        written as a file. See ${docs page}.
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
  options.programs.pi-coding-agent = {
    system = lib.mkOption {
      type = lib.types.nullOr textOrPath;
      default = null;
      example = lib.literalExpression "./pi-system.md";
      description = ''
        Replacement for pi's system prompt, as text or a path, written to
        {file}`SYSTEM.md` in {option}`programs.pi-coding-agent.configDir`.
        See ${docs "configuration.md"}.
      '';
    };

    skills = resourceOption "skills" "skills.md" "{ review = ./skills/review; }";
    prompts = resourceOption "prompts" "prompt-templates.md" ''{ "review.md" = ./review.md; }'';
    extensions = resourceOption "extensions" "extensions.md" ''{ "hello.ts" = ./hello.ts; }'';
    themes = resourceOption "themes" "themes.md" ''{ "my-theme.json" = ./my-theme.json; }'';
  };

  config = lib.mkIf cfg.enable {
    home.file =
      let
        at = name: "${cfg.configDir}/${name}";
      in
      lib.mergeAttrsList (
        lib.optional (cfg.system != null) { ${at "SYSTEM.md"} = fileFrom cfg.system; }
        ++ map (
          dir:
          lib.mapAttrs' (name: value: lib.nameValuePair (at "${dir}/${name}") (fileFrom value)) cfg.${dir}
        ) resourceDirs
      );
  };
}
