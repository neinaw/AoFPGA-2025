file_path = "./hardcaml/test/input2.txt"
init_pos = 50
ans = 0
with open(file_path, 'r') as file:
    max_rot = 0
    for line in file:
        rot = line.strip()
        max_rot = max(max_rot, int(rot[1::]))

    print(f"Maximum input rotation is {max_rot}")

with open(file_path, 'r') as file:
    for line in file:
        rot = line.strip()
        if rot[0] == 'L':
            init_pos = (init_pos - int(rot[1::])) % 100
        else:
            init_pos = (init_pos + int(rot[1::])) % 100

        if init_pos == 0:
            ans += 1

    print(f"answer part 1 is {ans}")


init_pos = 50
ans = 0
with open(file_path, 'r') as file:
    for line in file:
        rot = line.strip()
        val = int(rot[1::])
        ans += val // 100

        if rot[0] == 'R':
            ans += ((val % 100) + init_pos) // 100
            init_pos = (init_pos + int(rot[1::])) % 100

        else:
            if init_pos != 0:
                if (val % 100) >= init_pos:
                    ans += 1
            
            init_pos = (init_pos - int(rot[1::])) % 100

    print(f"answer part 2 is {ans}")