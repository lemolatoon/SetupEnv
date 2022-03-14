script_dir=$(cd $(dirname $0); pwd)
cd $script_dir/..


# config files
cp ./configs/* $HOME/ -iv
echo "single files are ok."
cp ./configs/.config/* $HOME/.config -irv
echo "files under .config are ok."

