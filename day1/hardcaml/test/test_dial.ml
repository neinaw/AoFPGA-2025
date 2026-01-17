open! Core
open! Hardcaml
open! Hardcaml_waveterm
open! Hardcaml_test_harness
module Dial = Solution.Dial
module Harness = Cyclesim_harness.Make (Dial.I) (Dial.O)

let ( <--. ) = Bits.( <--. )

let sample_input_values =
  [ 1, 68; 1, 30; 0, 48; 1, 5; 0, 60; 1, 55; 1, 1; 1, 99; 0, 14; 1, 82 ]
;;

let file = "input.txt"

let parse_line (line : string) : int * int =
  match line.[0] with
  | 'R' ->
    let value_str = String.chop_prefix_exn line ~prefix:"R" in
    0, Int.of_string value_str
  | 'L' ->
    let value_str = String.chop_prefix_exn line ~prefix:"L" in
    1, Int.of_string value_str
  | _ -> failwithf "Invalid input line format: %s" line ()
;;

let inputs_from_file ~file ~f =
  In_channel.with_file file ~f:(fun ic ->
    In_channel.iter_lines ic ~f:(fun line ->
      let sign, value = parse_line line in
      f (sign, value)))
;;

let simple_testbench (sim : Harness.Sim.t) =
  let inputs = Cyclesim.inputs sim in
  let outputs = Cyclesim.outputs sim in
  let cycle ?n () = Cyclesim.cycle ?n sim in
  let feed_inputs (sign, value) =
    inputs.din <--. value;
    inputs.valid <--. 1;
    inputs.sign <--. sign;
    cycle ();
    inputs.valid <--. 0;
    cycle ()
  in
  inputs.clear := Bits.vdd;
  cycle ();
  cycle ();
  inputs.clear := Bits.gnd;
  (* List.iter sample_input_values ~f:feed_inputs; *)
  inputs_from_file ~file ~f:feed_inputs;
  while not (Bits.to_bool !(outputs.o_valid)) do
    cycle ()
  done;
  let part1 = Bits.to_unsigned_int !(outputs.p1_count) in
  let part2 = Bits.to_unsigned_int !(outputs.p2_count) in
  print_s [%message "Answer" (part1 : int) (part2 : int)];
  cycle ~n:2 ()
;;

(* let waves_config =
  Waves_config.to_directory "/tmp"
  |> Waves_config.as_wavefile_format ~format:Vcd
;; *)
let waves_config = Waves_config.no_waves

let%expect_test "Solution Day 1" =
  Harness.run_advanced ~waves_config ~create:Dial.hierarchical simple_testbench;
  [%expect {| (Answer (part1 1089) (part2 6530)) |}]
;;
