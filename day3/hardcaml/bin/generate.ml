open! Core
open! Hardcaml
open! Solution

let generate_rtl () =
  let module Top =
    Solution.Top.Make (struct
      let depth = 128
      let width = 4
      let part_1 = true
    end)
  in
  let module C = Circuit.With_interface (Top.I) (Top.O) in
  let scope = Scope.create ~auto_label_hierarchical_ports:true () in
  let circuit = C.create_exn ~name:"top" (Top.hierarchical scope) in
  let rtl_circuits =
    Rtl.create ~database:(Scope.circuit_database scope) Verilog [ circuit ]
  in
  let rtl = Rtl.full_hierarchy rtl_circuits |> Rope.to_string in
  print_endline rtl
;;

let rtl_command =
  Command.basic
    ~summary:""
    [%map_open.Command
      let () = return () in
      fun () -> generate_rtl ()]
;;

let () = Command_unix.run (Command.group ~summary:"" [ "top", rtl_command ])
