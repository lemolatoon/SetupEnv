import sys
from src.util import print_b
import src.shell as sh
import os

def operation_with_bash(all: bool = False):
    # select package manager
    pkg = select_package_manager(all)

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

    if all:
        return

    print()
    print("Make sure sh.run `\033[33msource ~/.bashrc\033[0m`, then fish will be launched")
    print("After that, sh.run \033[33mthis script\033[0m again")


def select_package_manager(all=False) -> str:
    if all:
        return "apt"

    ans = ""
    pkg_mgr_list = ["apt", "pacman"]
    index: int = 0
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
        sh.direct("sudo apt-get update -y")
        sh.direct("sudo apt-get upgrade -y")
    elif pkg == "pacman":
        sh.run("sudo pacman -g")
        sh.run("sudo pacman -Syyu")

def install_packages(pkg_mgr: str):
    packages = ["tmux", "git", "wget"]
    print_b("Installing packages...")
    for pkg in packages:
        if pkg_mgr == "apt":
            sh.direct(f"sudo apt-get install {pkg}")
        elif pkg_mgr == "pacman":
            sh.run(f"pacman -S {pkg}")
    install_nvim()

def install_nvim():
    # v0.6.1
    current_dir = os.getcwd()
    os.chdir("/usr/local/bin")
    sh.run("wget https://github.com/neovim/neovim/releases/download/v0.6.1/nvim.appimage")
    os.chmod("nvim.appimage", 0o744)
    sh.run("ln nvim.appimage nvim")
    os.chdir(current_dir)
        

def configure_package():
    sh.run("git config --global core.editor nvim")

def install_fish(pkg):
    print_b("Installing fish and configuring...")
    if pkg == "apt":
        sh.direct("sudo apt-add-repository ppa:fish-shell/release-3")
        sh.direct("sudo apt-get update")
        sh.direct("apt-get install fish")
    elif pkg == "pacman":
        sh.run("pacman -S fish")

def configure_fish():
    home = os.getenv("HOME")
    try:
        with open(f"{home}/.bashrc", mode="a", encoding="utf_8") as bashrc:
            bashrc.write("\nexec fish")
    except:
        print_b("Duaring editting .bashrc, error occurs")
        print(sys.exec_info())
        sys.exit(0)
