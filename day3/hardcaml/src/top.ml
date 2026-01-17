open! Core
open! Hardcaml
open! Signal

module Make (P : sig
    val depth : int
    val width : int
    val part_1 : bool
  end) =
struct
  let target = if P.part_1 then 2 else 12
  let num_bits = 64

  module I = struct
    type 'a t =
      { clock : 'a
      ; clear : 'a
      ; valid : 'a
      ; cols : 'a [@bits 8] (* Upto 256 columns *)
      ; last : 'a
      ; din : 'a [@bits P.width]
      }
    [@@deriving hardcaml]
  end

  module O = struct
    type 'a t =
      { ans : 'a With_valid.t [@bits num_bits]
      ; ready : 'a
      }
    [@@deriving hardcaml]
  end

  module States = struct
    type t =
      | Idle
      | While
      | Push
      | Accumulate
      | Ans
    [@@deriving sexp_of, compare ~localize, enumerate]
  end

  module Hw_stack = Hw_stack.Make (struct
      let depth = P.depth
      let width = P.width
    end)

  let create scope (i : _ I.t) : _ O.t =
    let spec = Reg_spec.create ~clock:i.clock ~clear:i.clear () in
    let stack_scope = Scope.sub_scope scope "stack" in
    let open Always in
    let sm = State_machine.create (module States) spec in
    let%hw_var to_drop = Variable.reg spec ~width:8 in
    let%hw_var acc = Variable.reg spec ~width:num_bits in
    let%hw_var ans = Variable.reg spec ~width:num_bits in
    let flush_stack = Variable.wire ~default:gnd () in
    let clear_stack = flush_stack.value |: i.clear in
    let ready = Variable.wire ~default:gnd () in
    (* let%hw_var push = Variable.wire ~default:gnd () in
    let%hw_var pop = Variable.wire ~default:gnd () in *)
    let push = Variable.wire ~default:gnd () in
    let pop = Variable.wire ~default:gnd () in
    let gods_eye = Variable.reg spec ~width:(Int.ceil_log2 P.depth) in
    let stack_o =
      Hw_stack.create
        stack_scope
        { Hw_stack.I.clock = i.clock
        ; clear = clear_stack
        ; data_in = i.din
        ; gods_eye = gods_eye.value
        ; push = push.value
        ; pop = pop.value
        }
    in
    let o_valid = Variable.reg spec ~width:1 in
    compile
      [ sm.switch
          [ ( Idle
            , [ ready <-- vdd
              ; when_
                  i.valid
                  [ to_drop <-- i.cols -:. target
                  ; push <-- vdd
                  ; o_valid <-- gnd
                  ; sm.set_next While
                  ]
              ] )
          ; ( While
            , [ when_
                  i.valid
                  [ if_
                      (to_drop.value
                       >:. 0
                       &: (stack_o.empty <>:. 1)
                       &: (i.din >: stack_o.data_out))
                      [ to_drop <-- to_drop.value -:. 1; pop <-- vdd ]
                      [ sm.set_next Push ]
                  ]
              ] )
          ; ( Push
            , [ push <-- vdd
              ; ready <-- vdd
              ; if_ i.last [ sm.set_next Accumulate ] [ sm.set_next While ]
              ] )
          ; ( Accumulate
            , [ if_
                  (gods_eye.value <:. target)
                  [ acc
                    <-- uresize stack_o.gods_view ~width:num_bits
                        +: uresize
                             (acc.value *: of_unsigned_int 10 ~width:4)
                             ~width:num_bits
                  ; gods_eye <-- gods_eye.value +:. 1
                  ]
                  [ sm.set_next Ans; flush_stack <--. 1 ]
              ] )
          ; ( Ans
            , [ sm.set_next Idle
              ; acc <--. 0
              ; gods_eye <--. 0
              ; ans <-- ans.value +: acc.value
              ; o_valid <-- vdd
              ] )
          ]
      ];
    { O.ans = { value = ans.value; valid = o_valid.value }; O.ready = ready.value }
  ;;

  let hierarchical scope =
    let module Scoped = Hierarchy.In_scope (I) (O) in
    Scoped.hierarchical ~scope ~name:"top" create
  ;;
end
