#!/bin/bash
script_dir=$(cd "$(dirname "$0")"; pwd)
cd "$script_dir/.." || exit 1


# config files
mkdir -p "$HOME/.config"

for config_file in ./configs/.[!.]* ./configs/..?*; do
    if [ -f "$config_file" ]; then
        cp -iv "$config_file" "$HOME/"
    fi
done
echo "single files are ok."

cp -irv ./configs/.config/. "$HOME/.config/"

# AeroSpace runs this helper directly from its key bindings.
if [ -f "$HOME/.config/aerospace/swap-workspace.sh" ]; then
    chmod +x "$HOME/.config/aerospace/swap-workspace.sh"
fi
echo "files under .config are ok."
