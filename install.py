import subprocess
import sys
from src.op_with_bash import operation_with_bash
from src.op_with_fish import operation_with_fish
from src.util import print_b
import src.shell as sh

script_dir: str = __file__
script_dir = script_dir.split("/")
length = len(script_dir)
script_dir.pop(length - 1)
script_dir = "/".join(script_dir)
print_b(script_dir)


def main():
    if len(sys.argv) >= 2:
        if sys.argv[1] == "--all" or sys.argv[1] == "--a":
            all()
        else:
            show_help()

    is_fish = using_fish()
    if is_fish:
        print_b("You are using fish")
    else:
        print_b("You might be using bash")


    if not is_fish:
        sh.copy_config(script_dir)
        operation_with_bash()
    else:
        operation_with_fish()




def using_fish() -> bool:
    while True:
        print("Are you running from `\033[33mfish\033[0m`? [Y/N]: ", end="")
        ans = input()
        if ans == 'y' or ans == 'Y':
            return True
        elif ans == 'n' or ans == 'N':
            return False
    

def all():
    sh.copy_config(script_dir)
    operation_with_bash(all = True)
    operation_with_fish(all = True)
    sh.direct("exec fish")
    sys.exit(0)

def show_help():
    print(
        f"""Unsupported args: {sys.argv}\n
            help:
                --all, --a: Install all automatically by using apt"""
    )
    sys.exit(0)


if __name__ == "__main__":
    main()
