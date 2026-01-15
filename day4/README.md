# [Day 4](https://adventofcode.com/2025/day/4): Printing Department

## Build Instructions and Directory Layout

1. All hardcaml files are in `hardcaml/`. My AoC puzzle input is in `hardcaml/test/input.txt`. To build and run the solution to both parts, do:

    ```bash
    # run both parts
    cd hardcaml/
    dune runtest

    # run test for part 1 only
    dune build @runtest-part_1

    # run test for part 2 only
    dune build @runtest-part_2
    ```
    I use expect tests in the testbench, so running runtest should print nothing. To run with another input, you may:

    - change the contents of `input.txt` with your AoC input, then re-build.
    - run with `input2.txt` - another AoC input (I got this from a friend). To do this, change line #6 of both `test/test_conv2d.ml` `test/test_erode.ml`,  and re-build
        ```OCaml
        let file = "input2.txt"
        ```
    - run the test with your own file - first change the file variable to the name of your file, and add that file to the `deps` in `test/dune`

2. Part 1's solution is in `src/conv2d.ml`, its corresponding test is in `test/test_conv2d.ml`

3. Part 2's solution is in `src/erode.ml`, its corresponding test is in `test/test_erode.ml`. Note that the test drives stimulus to the design in `src/*`

3. The software solution can be run with
    ```bash
    python3 solution.py /path/to/input.txt
    ```

4. Generating the verilog:
    ```bash
    cd hardcaml
    dune build bin/generate.exe

    # for part 1
    ./bin/generate.exe conv2d

    # for part 2
    ./bin/generate.exe erode

    ```

## Approach and explanation

#### Assumptions:
1. The "."s in the input are treated as binary 0, and "@" as binary 1.
2. The testbench parses the input file as per the above format, and feeds it row-by-row, one entire row at a time.
3. From what I could tell, the rows were 135-140 bits wide, which is not an unrealistic input width
4. Testbench asserts valid while streaming the rows, and and last pulse when streaming the last row
5. The final answer fits in 16 bits.

#### Part 1 - `src/conv2d.ml`
There is an idea of the "neighbourhood" of a cell, which determines if its reachable or not. This lends itself nicely to a convolution approach.

The input grid is convolved with a 3*3 kernel, with zero padding. The kernel is basically the popcount of the neighbourhood of a cell.

Since each pixel is one bit, I chose to parallely compute an entire row's convolution at once, with each kernel being an 8-bit input popcount. For a 139 bit input (as was the case for me), we instance 139 of these kernels, with zero padding at the edges.

For each pixel, if the popcount of its neighbourhood is < 4, then it is removed from the output bitmap. We count the total bits removed in a counter.

Then conv output per row is 139 bits, on which we calculate the popcount again. This is the critical path which is log2(139) levels deep, not too slow but still significant. This popcount is accumulated over all 139 rows in a register. The result of the convolution is streamed out similar to how it was streamed-in.

Two line buffers store the previous two rows of data.

#### Part 2 - `src/erode.ml`
This part is trivial after part 1. We repeatedly convolve the input till no more rolls can be removed. For each iteration, we sample the rolls it removed, and accumulate it in a register.

`erode.ml` instances `conv2d.ml`

To store the output after each iteration, we use the [asynchronous memory primitive](https://www.janestreet.com/web-app/hardcaml-docs/designing-circuits/sequential_logic#memories) which is as wide and deep as the input grid (provided as a parameter)
