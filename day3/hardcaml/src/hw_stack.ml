open! Core
open! Hardcaml
open! Signal

module Make (P : sig
  val depth : int
  val width : int
end) =
struct
  let sp_width = Int.ceil_log2 P.depth
  let sp_width_exn = sp_width + 1
  let pow2_depth = Int.pow 2 sp_width
  module I = struct
    type 'a t =
    { clock : 'a
    ; clear : 'a
    ; data_in : 'a [@bits P.width]
    ; gods_eye : 'a [@bits sp_width]
    ; push : 'a
    ; pop : 'a
    }
    [@@deriving hardcaml]
  end

  module O = struct
    type 'a t =
    { data_out : 'a [@bits P.width]
    ; gods_view : 'a [@bits P.width]
    ; full : 'a
    ; empty : 'a
    }
    [@@deriving hardcaml]
  end

  let create _scope (i : _ I.t) : _ O.t =
    let spec = Reg_spec.create ~clock:i.clock ~clear:i.clear () in
    let sp =
      reg_fb spec ~enable:vdd ~width:sp_width_exn
        ~f:( (* simultaneous push & pop not allowed *)
          fun sp ->
          let pushing = i.push &: ((sel_top sp ~width:1) <>:. 1) in
          let popping = i.pop  &: (sp >:. 0) in
          mux2 pushing (sp +:. 1) (mux2 popping (sp -:. 1) sp)
        )
    in
    let full = (sel_top sp ~width:1) ==:. 1 in
    let empty = sp ==:. 0 in
    let write_port =
      { Write_port.write_clock = i.clock
      ; write_address = sel_bottom sp ~width:sp_width
      ; write_enable = i.push
      ; write_data = i.data_in
      }

    in
    let read_address = sel_bottom (mux2 empty sp (sp -:. 1)) ~width:sp_width in
    let mem =
      multiport_memory
        pow2_depth
        ~write_ports:[|write_port|]
        ~read_addresses:[|read_address; i.gods_eye|]
    in

    {O.data_out = mem.(0); full; empty; gods_view = mem.(1)}
;;
  let hierarchical _scope =
    let module Scoped = Hierarchy.In_scope (I) (O) in
    Scoped.hierarchical ~scope:_scope ~name:"stack" create

;;
end