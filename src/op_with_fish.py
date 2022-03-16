import src.shell as sh
from src.util import print_b
import os

script_dir: str = __file__
script_dir = script_dir.split("/")
length = len(script_dir)
script_dir.pop(length - 1)
script_dir = "/".join(script_dir)

def operation_with_fish():
    configure_bobthefish()
    install_powerline()

    home = os.getenv("HOME")
    sh.run_as_fish(f"source {home}/.config/fish/config.fish")

    print()
    sh.direct(f"{script_dir}/logo.sh")
    print_b("All settings are completed!!!")

def configure_bobthefish():
    print_b("Configuring theme...")
    if not omf_exsists():
        sh.run("curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish")
    sh.run_as_fish("omf update")
    sh.run_as_fish("omf install bobthefish")

def install_powerline():
    print_b("Installing fonts...")
    sh.run("git clone https://github.com/powerline/fonts.git --depth=1")
    os.chdir("fonts")
    sh.direct("./install.sh")
    os.chdir("..")
    sh.direct("rm -rf fonts")

def omf_exsists() -> bool:
    try:
        sh.run_as_fish("omf > /dev/null")
        return True
    except:
        return False

