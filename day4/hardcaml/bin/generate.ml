open! Core
open! Hardcaml
open! Solution

let size = 139

let generate_rtl_conv2d () =
  let module Conv2d =
    Solution.Conv2d.Make (struct
      let size = size
    end)
  in
  let module C = Circuit.With_interface (Conv2d.I) (Conv2d.O) in
  let scope = Scope.create ~auto_label_hierarchical_ports:true () in
  let circuit = C.create_exn ~name:"conv2d" (Conv2d.hierarchical scope) in
  let rtl_circuits =
    Rtl.create ~database:(Scope.circuit_database scope) Verilog [ circuit ]
  in
  let rtl = Rtl.full_hierarchy rtl_circuits |> Rope.to_string in
  print_endline rtl
;;

let generate_rtl_erode () =
  let module Erode =
    Solution.Erode.Make (struct
      let size = size
    end)
  in
  let module C = Circuit.With_interface (Erode.I) (Erode.O) in
  let scope = Scope.create ~auto_label_hierarchical_ports:true () in
  let circuit = C.create_exn ~name:"erode" (Erode.hierarchical scope) in
  let rtl_circuits =
    Rtl.create ~database:(Scope.circuit_database scope) Verilog [ circuit ]
  in
  let rtl = Rtl.full_hierarchy rtl_circuits |> Rope.to_string in
  print_endline rtl
;;

let rtl_command_conv2d =
  Command.basic
    ~summary:""
    [%map_open.Command
      let () = return () in
      fun () -> generate_rtl_conv2d ()]
;;

let rtl_command_erode =
  Command.basic
    ~summary:""
    [%map_open.Command
      let () = return () in
      fun () -> generate_rtl_erode ()]
;;

let () =
  Command_unix.run
    (Command.group
       ~summary:"RTL Generation tools"
       [ "conv2d", rtl_command_conv2d; "erode", rtl_command_erode ])
;;
