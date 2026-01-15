open! Core
open! Hardcaml
open! Signal

module Make (P: sig
  val size : int
end) = struct

  module I = struct
    type 'a t =
    { clock : 'a
    ; clear : 'a
    ; valid : 'a
    ; din   : 'a [@bits P.size]
    ; last  : 'a
    }
    [@@deriving hardcaml]
  end

  module O = struct
    type 'a t =
    { conv : 'a With_valid.t [@bits P.size]
    ; o_last : 'a
    ; ans : 'a [@bits 16]
    }
    [@@deriving hardcaml]
  end

  let create _scope (i : _ I.t) : _ O.t =
    let spec = Reg_spec.create ~clock:i.clock ~clear:i.clear () in 
    let din_padded = mux2 i.valid i.din (zero P.size) -- "din_padded" in
    let valid_pipe = reg spec ~enable:vdd i.valid -- "valid_pipe" in
    let valid_pipe3 = pipeline spec ~enable:vdd ~n:2 valid_pipe -- "valid_pipe3" in
    let last_pipe = reg spec i.last -- "last_pipe" in
    let spec_zz = Reg_spec.create ~clock:i.clock ~clear:(i.clear |: last_pipe) () in
    let last_pipe3 = pipeline spec ~enable:vdd ~n:3 i.last -- "last_pipe3" in
    let check neighbourhood = (popcount neighbourhood) <:. 4 in
    let line_buf_z = reg spec din_padded -- "line_buf_z" in
    let line_buf_zz = reg spec_zz ~enable:valid_pipe line_buf_z -- "line_buf_zz" in
    let conv_map = List.init P.size ~f:(fun i ->
      let get_bit row idx =
        if idx < 0 || idx >= P.size then gnd else row.:[idx, idx]
      in
      let neighbourhood = [
        get_bit line_buf_zz (i-1); get_bit line_buf_zz (i); get_bit line_buf_zz (i+1);
        get_bit line_buf_z  (i-1);                          get_bit line_buf_z  (i+1);
        get_bit din_padded  (i-1); get_bit din_padded  (i); get_bit din_padded  (i+1)
      ]
      in
      check (concat_msb neighbourhood) &: (get_bit line_buf_z i)
    )
    in
    let reachable_lst = (concat_lsb conv_map) -- "reachables" in
    let reachable_lst_pipe = reg spec (concat_lsb conv_map) in
    let o_buf = reg spec (reachable_lst ^: line_buf_z) ~enable:valid_pipe in
    let o_buf_pipe = reg spec o_buf in
    let reachables_popcount = popcount reachable_lst_pipe in
    let ans = reg_fb spec ~width:16 ~f:(fun d -> uresize (reachables_popcount) ~width:16 +: d) in

    {O.conv = {value = o_buf_pipe; valid = valid_pipe3}; O.o_last = last_pipe3; O.ans = ans}
  let hierarchical _scope =
  let module Scoped = Hierarchy.In_scope (I) (O) in
  Scoped.hierarchical ~scope:_scope ~name:"top" create

end
