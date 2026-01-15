# Advent of FPGA 2025

My solutions to the Day 1, 3 and 4 [Advent of Code 2025](https://adventofcode.com/2025) problems, written in Hardcaml for the Jane Street [Advent of FPGA](https://blog.janestreet.com/advent-of-fpga-challenge-2025/) challenge.


## Project Structure

The project follows a consistent directory layout to keep source logic, testing, and verilog generation separated, like in the [hardcaml template project](https://github.com/janestreet/hardcaml_template_project/tree/with-extensions).

* **`dayX/hardcaml/`**
    * **`src/`**: Hardcaml design sources
    * **`test/`**: Testbench and AoC problem's input files
    * **`generate/`**: Verilog generation
    
My approach and explanation of each day's solution and specific build instructions is in a local README in it's directory.

In `dayX/`, there are solutions to the AoC's problems in `python3`, along with some other python scripts for proof-of-concept.

## Prerequisites

* OCaml, Hardcaml and all other prerequisites detailed in the template project's github (linked above). This repository was tested with the OxCaml compiler, 5.2.0+ox. Before building and running tests, the 5.2.0+ox switch must be selected.
* `python3` interpreter for running the software solution and other proof-of-concept scripts.
