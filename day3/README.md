# [Day 3](https://adventofcode.com/2025/day/3): Lobby

## Build Instructions and Directory Layout

1. All hardcaml files are in `hardcaml/`. My AoC puzzle input is in `hardcaml/test/input.txt`. To build and run the solution to both parts, do:

    ```bash
    cd hardcaml/
    dune build @runtest-test_top
    ```
    I use expect tests in the testbench, so running test_top should print nothing. To run with another input, you may:

    - change the contents of `input.txt` with your AoC input, then re-build.
    - run with `input2.txt` - another AoC input (I got this from a friend). To do this, change line #19 of `test/test_top.ml` and re-build
        ```OCaml
        let file = "input2.txt"
        ```
    - run the test with your own file - first change the file variable to the name of your file, and add that file to the `deps` in `test/dune`

2. I have a sub-unit called `src/hw_stack.ml` which is instanced in top. This module is simple enough to validate its correctness using waveforms:
    ```bash
    cd hardcaml
    dune build @runtest-test_stack
    ```
    The output should print the path to the `.hardcamlwaveform` file, which can be viewed with
    ```bash
    hardcaml-waveform-viewer show /path/to/.hardcamlwaveform
    # hit <Esc> to exit the viewer
    ```

3. The software solution can be run with
    ```bash
    python3 solution.py /path/to/input.txt
    ```

4. The top-level design file is in `src/top.ml`.

5. Generating the verilog:
    ```bash
    cd hardcaml
    dune build bin/generate.exe
    ./bin/generate.exe top

    ```

## Approach and explanation

#### Assumptions:
1. The number of batteries in each battery bank, i.e. the number of columns in each row must fit in 8 bits.
2. The answer of both parts but Part 2 in particular must fit in 64 bits.
3. Each row (battery bank) is fed one battery at a time from left to right, over a valid/ready interface. The data width of this interface is 4 bits (BCD).
4. Rows are fed sequentially, after all columns in the row are fed.
5. For each battery bank, the testbench also sends the number of batteries (columns) with the first valid beat; why explained later.

#### Largest subsequence of an array

The goal is to find the largest number formed by a subsequence _k_ digits long of the input row, when read left to right, and without re-arranging the rows. _k_ <= _n_ where n is the size of the row.

Algorithm:
For each battery bank (row) in the input do:
1. Init: `stack = []`, `to_drop = len(row) - k`
2. Loop: For each `x` in `row`:
    * While `stack` exists, `stack.top < x`, and `to_drop > 0`:
        * `stack.pop()`
        * `to_drop -= 1`
    * `stack.push(x)`
3. Result: `stack[:k]`
4. Accumulate result over all rows

k = 2 for part 1, and k = 12 for part 2

#### Hardware Stack (LIFO) `src/hw_stack.ml`
Width of the input and depth of the stack are parameterized. Depth is a power of 2.

This uses the [asynchronous memory primitive](https://www.janestreet.com/web-app/hardcaml-docs/designing-circuits/sequential_logic#memories) of hardcaml, with some control logic for the _pop_ and _push_ functions. _push_ and _pop_ cannot be asserted simulatneously, if asserted, then push is given priority. The algorithm does not require this collision logic anyway. There are empty and full flags, the empty flag is used in the top level solution to always push the first battery of a bank onto the stack.

There is a second user-controlled read pointer, called *gods_eye* to convert the BCD answer in step 3. to an actual binary value. As the name suggests, *gods_eye* has free will to peek at any address in the stack. The data read from *gods_eye* is called *gods_view*, and is an output.

#### Top-level module `src/top.ml`
There is a parameter which controls which part (1/2) the top is for, and a parameter for the depth of the stack.

For part 1, to_drop is 100-2 = 98; for part 2, it's 88

The stack depth taken is 128, as the length of each row is 100

This implements a state machine of the algorithm defined above. The final indexing is performed with *gods_eye* and *gods_view*, and the answer is accumulated over all rows in a 64 bit register.

The stack is reset after each row is processed, in preparation for the next row.

There is back-pressure on the testbench by means of the valid/ready protocol, where the testbench drives valid and the DUT drives ready.
#### Top-level Module I/O, Params
```OCaml
module Make (P: sig
  val depth : int
  val width : int
  val part_1 : bool
end) = struct
  let target = if P.part_1 then 2 else 12
  let num_bits = 64
  module I = struct
    type 'a t =
    { clock : 'a
    ; clear : 'a
    ; valid : 'a
    ; cols  : 'a [@bits 8]
    ; last  : 'a
    ; din   : 'a [@bits P.width]
    }
    [@@deriving hardcaml]
  end

  module O = struct
    type 'a t =
    { ans   : 'a With_valid.t [@bits num_bits]
    ; ready : 'a
    }
    [@@deriving hardcaml]
  end
  ...
  (*State machine*)
end
```
The output `ans.valid` pulses high for one cycle after the computation is done.