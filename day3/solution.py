import sys
from pathlib import Path

def solve(file_path, part_1 = True):
    with open(file_path, 'r') as file:
        if part_1:
            l = 2
        else:
            l = 12

        ans = 0
        for line in file:
            line = line.rstrip('\n')
            stack = []
            to_drop = len(line) - l
            for digit in line:
                while to_drop > 0 and stack and int(stack[-1]) < int(digit):
                    stack.pop()
                    to_drop -= 1
                stack.append(digit)

            max_joltage_str = ""
            for j in stack:
                max_joltage_str += j

            # print(max_joltage_str[:l])
            ans += int(max_joltage_str[:l])

        return ans
        # print(ans)

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
        print(f"Error: The path '{input_path}' does not exist.")
        sys.exit(1)
    
    if not input_path.is_file():
        print(f"Error: '{input_path}' is a directory, not a file.")
        sys.exit(1)

    print(solve(file_path=input_path.resolve()))
    print(solve(file_path=input_path.resolve(), part_1=False))
