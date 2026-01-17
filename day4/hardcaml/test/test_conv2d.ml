open! Core
open! Hardcaml
open! Hardcaml_waveterm
open! Hardcaml_test_harness

let ( <--. ) = Bits.( <--. )
let file = "input.txt"

(* let waves_config =
  Waves_config.to_directory "/tmp"
  |> Waves_config.as_wavefile_format ~format:Hardcamlwaveform *)
let waves_config = Waves_config.no_waves

module Make_test (Config : sig
    (*file name defined in dune deps*)
    val file : string
  end) =
struct
  let size =
    In_channel.with_file file ~f:(fun ic ->
      match In_channel.input_line ic with
      | Some line -> String.length line
      | None -> raise_s [%message "Empty input file" (Config.file : string)])
  ;;

  module Conv2d = Solution.Conv2d.Make (struct
      let size = size
    end)

  module Harness = Cyclesim_harness.Make (Conv2d.I) (Conv2d.O)

  let simple_testbench (sim : Harness.Sim.t) =
    let inputs = Cyclesim.inputs sim in
    let outputs = Cyclesim.outputs sim in
    let cycle ?n () = Cyclesim.cycle ?n sim in
    let inputs_from_file ~file =
      let lines = In_channel.read_lines file in
      List.iteri lines ~f:(fun i line ->
        let parse_line ~line =
          String.map
            ~f:(function
              | '.' -> '0'
              | '@' -> '1'
              | _ -> '0')
            line
        in
        inputs.valid := Bits.vdd;
        inputs.last := Bits.gnd;
        if i = List.length lines - 1
        then inputs.last := Bits.vdd
        else inputs.last := Bits.gnd;
        inputs.din := Bits.of_string (parse_line ~line);
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
    inputs_from_file ~file;
    inputs.valid := Bits.gnd;
    cycle ();
    while not (Bits.to_bool !(outputs.o_last)) do
      cycle ()
    done;
    let answer = Bits.to_unsigned_int !(outputs.ans) in
    print_s [%message "Part 1" (answer : int)];
    cycle ();
    cycle ~n:2 ()
  ;;

  let run () =
    Harness.run_advanced ~waves_config ~create:Conv2d.hierarchical simple_testbench
  ;;
end

module Test1 = Make_test (struct
    let file = file
  end)

let%expect_test "Part 1" =
  Test1.run ();
  [%expect {| ("Part 1" (answer 1346)) |}]
;;
