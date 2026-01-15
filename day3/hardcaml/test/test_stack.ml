open! Core
open! Hardcaml
open! Hardcaml_waveterm
open! Hardcaml_test_harness
module Hw_stack = Solution.Hw_stack.Make(struct
  let depth = 4
  let width = 8
end)
module Harness = Cyclesim_harness.Make (Hw_stack.I) (Hw_stack.O)

let ( <--. ) = Bits.( <--. )
let simple_testbench (sim: Harness.Sim.t) =
  let inputs = Cyclesim.inputs sim in
  let outputs = Cyclesim.outputs sim in
  let cycle ?n () = Cyclesim.cycle ?n sim in

  let check_flags ~expected_empty ~expected_full =
    let empty = Bits.to_int_trunc !(outputs.empty) in
    let full = Bits.to_int_trunc !(outputs.full) in
    if empty <> expected_empty || full <> expected_full then
      raise_s [%message "Status Check Failed" 
                (expected_empty : int) (empty : int)
                (expected_full : int) (full : int)]
  in

  let step ?(push=false) ?(pop=false) ?(data=0) ?(eye=0) () =
    inputs.push := if push then Bits.vdd else Bits.gnd;
    inputs.pop := if pop then Bits.vdd else Bits.gnd;
    inputs.data_in <--. data;
    inputs.gods_eye <--. eye;
    cycle ();
    inputs.push := Bits.gnd;
    inputs.pop := Bits.gnd
  in

  inputs.clear := Bits.vdd;
  cycle ();
  inputs.clear := Bits.gnd;
  check_flags ~expected_empty:1 ~expected_full:0;

  for i = 1 to 4 do
    step ~push:true ~data:(i * 10) ();
    let expected_full = if i = 4 then 1 else 0 in
    check_flags ~expected_empty:0 ~expected_full;
  done;

  (* 3. Empty the Stack *)
  for _ = 1 to 4 do
    step ~pop:true ();
  done;
  check_flags ~expected_empty:1 ~expected_full:0;
;;

(* let waves_config = Waves_config.no_waves *)
let waves_config =
  Waves_config.to_directory "/tmp"
  |> Waves_config.as_wavefile_format ~format:Hardcamlwaveform
;;

let%expect_test "Hw_stack Test" =
  Harness.run_advanced ~waves_config ~create:Hw_stack.hierarchical simple_testbench;
  [%expect {||}]
;;
