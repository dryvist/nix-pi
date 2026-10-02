# The module's one script. Home Manager has no option for a file that the
# program also writes (its own zed-editor and vscode modules merge at
# activation the same way), so pi's settings.json is merged, not linked.
#
#   pi-merge-settings <settings.json> <declared.json>
#
# Declared keys replace the same keys in the existing file; every other key
# stays. A leftover symlink becomes a real file. Invalid JSON is left as is.
{ pkgs }:
pkgs.writeShellApplication {
  name = "pi-merge-settings";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.jq
  ];
  text = ''
    target=$1
    declared=$2

    mkdir -p "$(dirname "$target")"
    [ ! -L "$target" ] || rm "$target"

    if [ ! -s "$target" ]; then
      install -m 644 "$declared" "$target"
    elif merged=$(jq -s '.[0] * .[1]' "$target" "$declared"); then
      printf '%s\n' "$merged" > "$target"
    else
      echo "pi: $target is not valid JSON; left unchanged" >&2
    fi
  '';
}
