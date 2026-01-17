open! Core
open! Hardcaml
open! Solution

let generate_dial_rtl () =
  let module C = Circuit.With_interface (Dial.I) (Dial.O) in
  let scope = Scope.create ~auto_label_hierarchical_ports:true () in
  let circuit = C.create_exn ~name:"dial_top" (Dial.hierarchical scope) in
  let rtl_circuits =
    Rtl.create ~database:(Scope.circuit_database scope) Verilog [ circuit ]
  in
  let rtl = Rtl.full_hierarchy rtl_circuits |> Rope.to_string in
  print_endline rtl
;;

let dial_rtl_command =
  Command.basic
    ~summary:""
    [%map_open.Command
      let () = return () in
      fun () -> generate_dial_rtl ()]
;;

let () = Command_unix.run (Command.group ~summary:"" [ "dial-top", dial_rtl_command ])
