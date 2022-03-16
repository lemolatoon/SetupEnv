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

def main():
    is_fish = using_fish()
    if is_fish:
        print_b("You are using fish")
    else:
        print_b("You might be using bash")


    if not is_fish:
        print_b("copy config files")
        sh.direct(f"fish .{script_dir}/src/copy_config.sh")
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
    



if __name__ == "__main__":
    main()
