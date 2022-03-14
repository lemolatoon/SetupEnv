import subprocess
import sys
import os

script_dir: str = __file__
script_dir = script_dir.split("/")
length = len(script_dir)
script_dir.pop(length - 1)
script_dir = "/".join(script_dir)

def main():
    is_fish = using_fish()
    if is_fish:
        print_b("You are using fish")
    else:
        print_b("You might be using bash")


    if not is_fish:
        print_b("copy config files")
        os.system(f"fish .{script_dir}/src/copy_config.sh")
        operation_with_bash()
    else:
        operation_with_fish()

def operation_with_fish():
    configure_bobthefish()
    install_powerline()

    home = os.getenv("HOME")
    run_as_fish(f"source {home}/.config/fish/config.fish")

    print()
    os.system(f".{script_dir}/src/logo.sh")
    print_b("All settings are completed!!!")

def configure_bobthefish():
    print_b("Configuring theme...")
    if not omf_exsists():
        run("curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish")
    run_as_fish("omf update")
    run_as_fish("omf install bobthefish")

def install_powerline():
    print_b("Installing fonts...")
    run("git clone https://github.com/powerline/fonts.git --depth=1")
    os.chdir("fonts")
    os.system("./install.sh")
    os.chdir("..")
    os.system("rm -rf fonts")


def operation_with_bash():
    # select package manager
    pkg = select_package_manager()

    # update package manager
    update_package_manager(pkg)

    # install packages from package manager
    install_packages(pkg)

    # configure some packages
    configure_package()

    # install fish, which will replace bash in this environment
    install_fish(pkg)

    # write `exec fish` at the end of $HOME/.bashrc
    configure_fish()

    print()
    print("Make sure run `\033[33msource ~/.bashrc\033[0m`, then fish will be launched")
    print("After that, run \033[33mthis script\033[0m again")


def select_package_manager() -> str:
    ans = ""
    pkg_mgr_list = ["apt", "pacman"]
    index: int = 0;
    while ans != 'y' and ans != 'Y':
        print(f"Are you using Package Manager: \033[33m{pkg_mgr_list[index]}\033[0m? [Y/N]: ", end="")
        ans: str = input()
        if ans == 'n' or ans == 'N':
            index += 1
            if index >= len(pkg_mgr_list):
                print(f"Useable package manager is only {pkg_mgr_list}")
                print("Terminating script....")
                sys.exit(0)
    return pkg_mgr_list[index]


def update_package_manager(pkg: str):
    print_b("Updating package manager")
    if pkg == "apt":
        os.system("sudo apt-get update")
        os.system("sudo apt-get upgrade -y")
    elif pkg == "pacman":
        run("sudo pacman -g")
        run("sudo pacman -Syyu")

def install_packages(pkg: str):
    packages = ["neovim", "tmux", "git"]
    print_b("Installing packages...")
    if pkg == "apt":
        os.system("apt-get install neovim tmux git")
    elif pkg == "pacman":
        for pkg in packages:
            run(f"pacman -S {pkg}")

def configure_package():
    run("git config --global core.editor nvim")

def install_fish(pkg):
    print_b("Installing fish and configuring...")
    if pkg == "apt":
        os.system("sudo apt-add-repository ppa:fish-shell/release-3")
        os.system("sudo apt-get update")
        os.system("apt-get install fish")
    elif pkg == "pacman":
        run("pacman -S fish")

def using_fish() -> bool:
    while True:
        print("Are you running from `\033[33mfish\033[0m`? [Y/N]: ", end="")
        ans = input()
        if ans == 'y' or ans == 'Y':
            return True
        elif ans == 'n' or ans == 'N':
            return False
    
    

def configure_fish():
    home = os.getenv("HOME")
    try:
        with open(f"{home}/.bashrc", mode="a", encoding="utf_8") as bashrc:
            bashrc.write("\nexec fish")
    except:
        print_b("Duaring editting .bashrc, error occurs")
        print(sys.exec_info())
        sys.exit(0)



def run(cmd: str) -> str:
    print()
    try:
        output = subprocess.check_output(cmd.split(" "))
        return output
    except:
        print("\033[31m" + "command calls failed. the command was: {}".format(cmd) + "\033[0m")

        if "sudo" in cmd:
            print("make sure run this script with `\033[31msudo\033[0m`")

        print("\nDo you want to call the command \033[33magain\033[0m from os.system(cmd)? [Y/N]: ", end="")
        ans: str = input()
        if ans == 'Y' or ans == 'y':
            os.system(cmd)
            while True:
                print("Do you want to continue runnig anyway? [Y/N]", end="")
                ans = input()
                if ans == 'y' or ans == 'Y':
                    return
                elif ans == 'n' or ans == 'N':
                    break


        print("\nBecause of Error of shell, terminating script...")
        sys.exit(0)

    print()

def run_as_fish(s: str):
    os.system(f"echo {s} | fish")

def omf_exsists() -> bool:
    try:
        run_as_fish("omf > /dev/null")
        return True
    except:
        return False

def print_b(s: str, color="green"):
    end = "\033[0m"
    if color == "blue":
        start="\033[34m"
    elif color == "green":
        start="\033[32m"

    print("{}{}{}".format(start, s, end))

if __name__ == "__main__":
    main()
