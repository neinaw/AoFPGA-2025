open! Core
open! Hardcaml
open! Signal

let init_pos = of_int_trunc ~width:8 50
let divisor = of_int_trunc ~width:16 100

(* Montgomery number for n / 100 *)
let magic_number = of_int_trunc ~width:16 5243
let e = 2
let sh_pre = 2
let sh_post = 3
let _N = 16

module I = struct
  type 'a t =
    { clock : 'a
    ; clear : 'a
    ; din   : 'a [@bits 16]
    ; valid : 'a
    ; sign  : 'a
    }
  [@@deriving hardcaml]
end

module O = struct
  type 'a t =
  { p1_count : 'a [@bits 16]
  ; p2_count : 'a [@bits 16]
  ; o_valid  : 'a
  }
  [@@deriving hardcaml]
end

let create scope (i : _ I.t) : _ O.t =

  let spec = Reg_spec.create ~clock:i.clock ~clear:i.clear () in
  let%hw_var pos = Always.Variable.reg spec ~width:8 ~clear_to:init_pos in
  let%hw_var p1_count = Always.Variable.reg spec ~width:16 in
  let%hw_var p2_count = Always.Variable.reg spec ~width:16 in
  let valid_pipe = pipeline spec ~n:2 i.valid in
  let valid_out = reg spec valid_pipe in
  let din_pipe = reg spec i.din in
  let sign_pipe = pipeline spec i.sign ~n:2 in
  let product =
    srl (magic_number *: (srl i.din ~by:sh_pre)) ~by:(_N - e + sh_post)
  in
  let quo = reg spec (uresize product ~width:16) in
  let quo_pipe = reg spec quo in
  let rem = reg spec (uresize (din_pipe -: (uresize (quo *: divisor) ~width:16)) ~width:8) in
  Always.(compile [
    when_ (valid_pipe ==:. 1)
      [ if_ (sign_pipe ==:. 0) (*Rotating Right*)
        [ if_ (rem +: pos.value >:. 100)
          [ pos <-- ((rem +: pos.value) -:. 100) ]
          [ if_ ( (rem +: pos.value ==:. 100) |: (rem +: pos.value ==:. 0)) (*if din= 0 mod 100 and pos = 0*)
              [ p1_count <-- p1_count.value +:. 1
              ; pos <--. 0
              ] [ pos <-- rem +: pos.value ]
          ]
        ]
        [ (*Rotating Left*)
          if_ (rem >: pos.value)
            [ pos <-- ((pos.value +:. 100) -: rem) ; p2_count <-- p2_count.value +: quo_pipe +:. 1]
            [ if_ (rem ==: pos.value)
                [ pos <--. 0
                ; p1_count <-- p1_count.value +:. 1 
                ]
                [ pos <-- pos.value -: rem ] 
            ]
        ]
      (* Parallel part 2 count logic*)
      ; let default = p2_count.value +: quo_pipe in
          if_ (sign_pipe ==:. 0)
          [ if_ (rem +: pos.value >=:. 100) [p2_count <-- default +:. 1] [p2_count <-- default] ]
          [ if_ (pos.value ==:. 0) [p2_count <-- default]
            [ if_ (rem >=: pos.value) [ p2_count <-- default +:.1 ] [ p2_count <-- default ]
            ]
          ]
      ]
  ]);

  {O.p1_count = p1_count.value; O.p2_count = p2_count.value; O.o_valid = valid_out}
;;

let hierarchical scope =
  let module Scoped = Hierarchy.In_scope (I) (O) in
  Scoped.hierarchical ~scope ~name:"dial" create
;;