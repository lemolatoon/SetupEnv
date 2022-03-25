import subprocess
import sys
import os

from src.util import print_b

def run(cmd: str) -> str:
    print()
    try:
        output = subprocess.check_output(cmd.split(" "))
        return output
    except:
        print("\033[31m" + "command calls failed. the command was: {}".format(cmd) + "\033[0m")

        if "sudo" in cmd:
            print("make sure run this script with `\033[31msudo\033[0m`")

        # ask whether run `os.system(cmd)` or not
        while True:
            print("\nDo you want to call the command \033[33magain\033[0m from os.system(cmd)? [Y/N]: ", end="")
            ans: str = input()
            if ans == 'Y' or ans == 'y':
                direct(cmd)
                break
            elif ans == 'n' or ans == 'N':
                break

        # ask whether continue running this script
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

def direct(s: str):
    os.system(s)

def copy_config(script_dir: str):
    print_b("copy config files")
    direct(f"bash .{script_dir}/src/copy_config.sh")