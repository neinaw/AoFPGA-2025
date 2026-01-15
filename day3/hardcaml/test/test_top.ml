open! Core
open! Hardcaml
open! Hardcaml_waveterm
open! Hardcaml_test_harness

module Config1 = struct
  let depth = 128
  let width = 4
  let part_1 = true
end

module Config2 = struct
  let depth = 128
  let width = 4
  let part_1 = false
end

let ( <--. ) = Bits.( <--. )
let file = "input.txt"

let inputs_from_file ~file ~f =
  In_channel.with_file file ~f:(fun ic ->
      In_channel.iter_lines ic ~f)
let waves_config = Waves_config.no_waves

module Make_test (Config : sig
  val depth : int
  val width : int
  val part_1 : bool
end) = struct
  module Top = Solution.Top.Make (Config)
  module Harness = Cyclesim_harness.Make (Top.I) (Top.O)
  let simple_testbench (sim: Harness.Sim.t) =
    let inputs = Cyclesim.inputs sim in
    let outputs = Cyclesim.outputs sim in
    let cycle ?n () = Cyclesim.cycle ?n sim in

    let feed_line line =
      String.iteri line ~f:(fun i c ->
          if i = 0 then
            inputs.cols <--. String.length line
          else if i = String.length line - 1 then
            inputs.last := Bits.vdd
          else
            inputs.last := Bits.gnd;

          inputs.din <--. Char.to_int c - Char.to_int '0';
          inputs.valid := Bits.vdd;

          while not (Bits.to_bool !(outputs.ready)) do
            cycle ()
          done;

          cycle ());
      inputs.valid := Bits.gnd;
      inputs.last := Bits.gnd;
      cycle ()
    in

    (* Main Test sequence *)
    inputs.clear := Bits.vdd;
    cycle ();
    cycle ();
    inputs.clear := Bits.gnd;
    inputs_from_file ~file ~f:feed_line;
    while not (Bits.to_bool !(outputs.ans.valid)) do
      cycle ()
    done;
    let answer = Bits.to_unsigned_int !(outputs.ans.value) in
    let message_str = if Config.part_1 then "Part 1" else "Part 2" in
    print_s [%message message_str (answer : int)];
    cycle ~n:2 ()

  let run () =
    Harness.run_advanced ~waves_config ~create:Top.hierarchical simple_testbench
end

module Test1 = Make_test (Config1)
module Test2 = Make_test (Config2)

let%expect_test "Part 1" =
  Test1.run ();
  [%expect {| ("Part 1" (answer 16993)) |}]
;;

let%expect_test "Part 2" =
  Test2.run ();
  [%expect {| ("Part 2" (answer 168617068915447)) |}]
;;
