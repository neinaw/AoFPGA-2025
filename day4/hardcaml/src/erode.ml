open! Core
open! Hardcaml
open! Signal

module Make (P : sig
    val size : int
  end) =
struct
  let width = Int.ceil_log2 P.size

  module I = struct
    type 'a t =
      { clock : 'a
      ; clear : 'a
      ; valid : 'a
      ; din : 'a [@bits P.size]
      ; last : 'a
      }
    [@@deriving hardcaml]
  end

  module O = struct
    type 'a t = { ans : 'a With_valid.t [@bits 16] } [@@deriving hardcaml]
  end

  module Conv2d = Conv2d.Make (struct
      let size = P.size
    end)

  let create scope (i : _ I.t) : _ O.t =
    let spec = Reg_spec.create ~clock:i.clock ~clear:i.clear () in
    let conv2d_scope = Scope.sub_scope scope "conv2d" in
    let din_mux = wire P.size in
    let valid_mux = wire 1 in
    let last_mux = wire 1 in
    let conv2d_o =
      Conv2d.create
        conv2d_scope
        { Conv2d.I.clock = i.clock
        ; clear = i.clear
        ; valid = valid_mux
        ; din = din_mux
        ; last = last_mux
        }
    in
    let ans = reg spec conv2d_o.ans ~enable:(conv2d_o.conv.valid &: conv2d_o.o_last) in
    let wr_addr_gen =
      reg_fb spec ~enable:conv2d_o.conv.valid ~width ~f:(mod_counter ~max:(P.size - 1))
      -- "wr_addr_gen"
    in
    let wr_port =
      { Write_port.write_clock = i.clock
      ; write_address = wr_addr_gen
      ; write_enable = conv2d_o.conv.valid
      ; write_data = conv2d_o.conv.value
      }
    in
    let rd_addr = wire width in
    let start_counting =
      conv2d_o.ans <>: ans &: (conv2d_o.o_last &: conv2d_o.conv.valid) -- "start_counting"
    in
    let feed_en =
      (*if rd_addr = 0 then start_counting else 1*)
      mux2 (rd_addr ==:. 0) start_counting vdd -- "feed_en"
    in
    let rd_addr_gen =
      reg_fb spec ~enable:feed_en ~width ~f:(mod_counter ~max:(P.size - 1))
      -- "rd_addr_gen"
    in
    let rd_addr_last = rd_addr ==:. P.size - 1 in
    let conv2d_buf =
      multiport_memory P.size ~write_ports:[| wr_port |] ~read_addresses:[| rd_addr_gen |]
    in
    let ans_valid =
      reg spec (conv2d_o.ans ==: ans) &: (conv2d_o.o_last &: conv2d_o.conv.valid)
    in
    rd_addr <-- rd_addr_gen;
    valid_mux <-- mux2 i.valid vdd feed_en;
    din_mux <-- mux2 i.valid i.din conv2d_buf.(0);
    last_mux <-- mux2 i.valid i.last rd_addr_last;
    { O.ans = { value = ans; valid = ans_valid } }
  ;;

  let hierarchical scope =
    let module Scoped = Hierarchy.In_scope (I) (O) in
    Scoped.hierarchical ~scope ~name:"erode" create
  ;;
end
