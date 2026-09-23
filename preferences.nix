# Our choices where they differ from pi's defaults. Optional: import
# `homeModules.preferences` to apply them; any value can still be overridden.
# Values are `programs.pi` options (see modules/pi.nix).
{
  settings = {
    defaultThinkingLevel = "high"; # default "medium"
    quietStartup = true; # default false
    collapseChangelog = true; # default false
    enableInstallTelemetry = false; # default true
  };
}
