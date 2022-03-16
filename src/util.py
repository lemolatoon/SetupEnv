def print_b(s: str, color="green"):
    end = "\033[0m"
    if color == "blue":
        start="\033[34m"
    elif color == "green":
        start="\033[32m"

    print("{}{}{}".format(start, s, end))
