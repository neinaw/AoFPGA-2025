import sys
from pathlib import Path

def check(i, j, lst):
    if lst[i][j]:
        count = lst[i-1][j-1] + lst[i-1][j] + lst[i-1][j+1] + lst[i][j-1] + lst[i][j+1] + lst[i+1][j-1] + lst[i+1][j] + lst[i+1][j+1]
        return count < 4
    else:
        return False

def parse_file(file):
    with open(file, 'r') as file:
        parsed_file = []
        for i, line in enumerate(file):
            parsed_line = [False]
            line = line.rstrip("\n")
            for c in line:
                if c == "@":
                    parsed_line.append(True)
                else:
                    parsed_line.append(False)
                
            parsed_line.append(False)

            if i == 0:
                init = [False] * len(parsed_line)
                parsed_file.append(init)
                parsed_file.append(parsed_line)
            
            else:
                parsed_file.append(parsed_line)

        new_cols = len(parsed_file[0])
        parsed_file.append([False] * new_cols)
    
    return parsed_file

def remove(lst, switch=False):
    to_remove = []
    
    for i in range(1, len(lst) - 1):
        for j in range(1, len(lst[0]) - 1):
            if check(i, j, lst):
                to_remove.append((i, j))

    removed = len(to_remove)
    print(f"removed :{removed}")

    for i, j in to_remove:
        lst[i][j] = False

    if not switch and removed > 0:
        removed += remove(lst, switch=False)

    return removed

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Error: No file path provided.")
        print("Usage: python solution.py <file_path>")
        sys.exit(1)

    elif len(sys.argv) > 2:
        print("Too many arguments!")
        print("Usage: python solution.py <file_path>")
        sys.exit(1)

    input_path = Path(sys.argv[1])


    if not input_path.exists():
        print(f"Error: The path '{input_path.resolve()}' does not exist.")
        sys.exit(1)
    
    if not input_path.is_file():
        print(f"Error: '{input_path.resolve()}' is a directory, not a file.")
        sys.exit(1)

    # Make 2 copies to avoid pass by reference artefacts!
    padded1 = parse_file(input_path)
    padded2 = parse_file(input_path)
    ans1 = remove(padded1, True)
    ans2 = remove(padded2, False)
    print(f"Part 1: {ans1}")
    print(f"Part 2: {ans2}")
