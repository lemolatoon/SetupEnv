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

    # configure git config
    configure_git_config()

    # install fish, which will replace bash in this environment
    install_fish(pkg)

    shell = select_shell()
    # write `exec fish` at the end of $HOME/.bashrc
    configure_fish(shell)

    if all:
        return

    print()
    print(
        f"Make sure sh.run `\033[33msource ~/.{shell}rc\033[0m`, then fish will be launched")
    print("After that, sh.run \033[33mthis script\033[0m again")


def configure_git_config():
    sh.run('git config --global user.name "lemolatoon"')
    sh.run('git config --global user.email 63438515+lemolatoon@users.noreply.github.com')


def select_package_manager(all=False) -> str:
    if all:
        return "apt"

    ans = ""
    pkg_mgr_list = ["apt", "brew", "pacman"]
    index: int = 0
    while ans != 'y' and ans != 'Y':
        print(
            f"Are you using Package Manager: \033[33m{pkg_mgr_list[index]}\033[0m? [Y/N]: ", end="")
        ans: str = input()
        if ans == 'n' or ans == 'N':
            index += 1
            if index >= len(pkg_mgr_list):
                print(f"Useable package manager is only {pkg_mgr_list}")
                print("Terminating script....")
                sys.exit(0)
    return pkg_mgr_list[index]


def select_shell(all=False) -> str:
    if all:
        return "bash"

    ans = ""
    shell_list = ["bash", "zsh"]
    index: int = 0
    while ans != 'y' and ans != 'Y':
        print(
            f"Are you using Shell: \033[33m{shell_list[index]}\033[0m? [Y/N]: ", end="")
        ans: str = input()
        if ans == 'n' or ans == 'N':
            index += 1
            if index >= len(shell_list):
                print(f"Useable shell is only {shell_list}")
                print("Terminating script....")
                sys.exit(0)
    return shell_list[index]


def update_package_manager(pkg: str):
    print_b("Updating package manager")
    if pkg == "apt":
        sh.direct("sudo apt-get update -y")
        sh.direct("sudo apt-get upgrade -y")
    elif pkg == "pacman":
        sh.run("sudo pacman -g")
        sh.run("sudo pacman -Syyu")
    elif pkg == "pacman":
        sh.direct("brew update -y")
        sh.direct("brew upgrade -y")


def install_packages(pkg_mgr: str):
    packages = ["tmux", "git", "wget", "nvim"]
    print_b("Installing packages...")
    for pkg in packages:
        if pkg_mgr == "apt":
            sh.direct(f"sudo apt-get install {pkg}")
        elif pkg_mgr == "pacman":
            sh.run(f"pacman -S {pkg}")
        elif pkg_mgr == "brew":
            sh.direct(f"brew install {pkg}")
    # install_nvim()


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
        sh.direct("pacman -S fish")
    elif pkg == "brew":
        sh.direct("brew install fish")
    else:
        print("No suitable package manager found.")
        sys.exit(1)


def configure_fish(shell: str):
    home = os.getenv("HOME")
    try:
        with open(f"{home}/.{shell}rc", mode="a", encoding="utf_8") as shellrc:
            shellrc.write("\nexec fish")
    except:
        print_b(f"Duaring editting .{shell}rc, error occurs")
        print(sys.exec_info())
        sys.exit(0)
