#!/bin/bash
script_dir=$(cd $(dirname $0); pwd)
cd $script_dir/..


# config files
mkdir $HOME/.config -p
cp -iv ./configs/.* $HOME/ 
echo "single files are ok."
cp -irv ./configs/.config/* $HOME/.config
echo "files under .config are ok."

