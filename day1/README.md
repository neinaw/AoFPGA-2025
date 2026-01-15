# [Day 1](https://adventofcode.com/2025/day/1): Secret Entrance

## Build Instructions and Directory Layout

1. All hardcaml files are in `hardcaml/`. My AoC input is in `hardcaml/test/input.txt`. To build and run the solution to both parts, do:

    ```bash
    cd hardcaml/
    dune runtest
    # alternatively, run the test using its alias
    dune build @runtest-test_dial
    ```
    I use expect tests in the testbench, so upon running runtest, nothing should be printed. To run with another input, you may:

    - change the contents of `input.txt` with your AoC input, then re-build.
    - run with `input2.txt` - another AoC input (I got this from a friend). To do this, change line #10 of `test/test_dial.ml` and re-build
        ```OCaml
        let file = "input2.txt"
        ```
    - run the test with your own file - first change the file variable to the name of your file, and add that file to the `deps` in `test/dune`

2. The software solution can be run with
    ```bash
    python3 solution.py
    ```

3. The design file is in `src/dial.ml`.

4. The file `reciprocal_mult.py` is a helper script that generates some parameters required for the design, discussed below

5. Generating the verilog:
    ```bash
    cd hardcaml
    dune build bin/generate.exe
    ./bin/generate.exe dial-top

    ```

## Approach and explanation of `dial.ml`

#### Assumptions:
1. Input rotation's magnitude can fit in 16 bits - the puzzle inputs have a maximum rotation of 999, which should work.
2. Input is fed serially, one rotation at a time. For example, the puzzle's example input is fed in 10 cycles.

3. One bit is used for the direction (sign). R encoded as 0, and L encoded as 1.

3. The testbench performs the encoding and parsing of the input file, for example:
    ```
    R1230 = (0, 16'h4CE)
    L99 = (1, 16'h63)
    ```

#### Part 1
The dial's new position is a modulo-100 addition/subtraction of the input and it's current position. On each input, I just check the dial's new position and increment a counter if it's value is zero.

The modulo-100 operation is performed using Montgomery division by a fixed constant. The relevant section is discussed in this [document](https://gmplib.org/~tege/divcnst-pldi94.pdf) [Section 4].

Since the divisor is a run-time invariant, we can hardcode division as reciprocal multiplication by a constant, and with some clever shifting get an answer that is correct for all 16 bit dividends.

The script `reciprocal_mult.py` calculates the parameters, and also performs a brute force check of all possible 16 bit dividends. The final expression is:
```
n / 100 = (m * (n >> sh_pre)) >> (N-e) >> sh_post

Run-time invariants (N, d, m, e, sh_pre, sh_post) = (16, 100, 5243, 2, 2, 3)
```
As the shifting operations are with constants, they're mere wire re-orderings and the entire product can be computed in one cycle using a 16 bit multiplier. The quotient produced is 32 bits of which the top 16 bits can be safely dropped to get the quotient `q`.

The modulo is computed using the Division Algorithm and another 16 bit multiplier:
```
n % 100 = n - (q * 100)
```

This entire operation can be computed in 2 cycles, which allows for a nice pipelined approach for dial.ml

#### Part 2

For both 'L' and 'R' rotations, the zero-crossing will increase by at least (rot % 100) where rot is the rotation magnitude. We can save this as a default increment to our answer for each rotation.

Then for 'R' rotations, we just need to check if (rot % 100) + initial position >= 100, and increment by 1 if true.

For 'L' rotations, we check if (rot % 100) >= initial position and increment by 1 if true.

The new dial position logic is same as in Part 1
#### Module I/O
```OCaml
module I = struct
  type 'a t =
    { clock : 'a
    ; clear : 'a
    ; din   : 'a [@bits 16]
    ; valid : 'a
    ; sign  : 'a
    }
  [@@deriving hardcaml]
end

module O = struct
  type 'a t =
  { p1_count : 'a [@bits 16]
  ; p2_count : 'a [@bits 16]
  ; o_valid  : 'a
  }
  [@@deriving hardcaml]
end
```
The input `valid` is held high for the entire file. The output `o_valid` pulses high for one cycle after the computation is done.