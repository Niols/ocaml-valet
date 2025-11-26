Test the valet PPX transformations
=================================

Setup
-----

  $ test_valet() { ocamlc -ppx 'valet --as-ppx' -dsource -c "$1" 2>&1; }

Simple function
---------------

  $ cat examples/good/simple_function.ml
  val add_one : int -> int
  let add_one x = x + 1

  $ test_valet examples/good/simple_function.ml
  let add_one : int -> int = fun x -> x + 1

Multiple parameters
-------------------

  $ cat examples/good/multiple_params.ml
  val add : int -> int -> int
  let add x y = x + y

  $ test_valet examples/good/multiple_params.ml
  let add : int -> int -> int = fun x y -> x + y

Value (no parameters)
---------------------

  $ cat examples/good/value.ml
  val forty_two : int
  let forty_two = 42

  $ test_valet examples/good/value.ml
  let forty_two : int = 42

Mutually recursive functions
-----------------------------

  $ cat examples/good/mutual_recursion.ml
  val is_even : int -> bool
  val is_odd : int -> bool
  let rec is_even n = if n = 0 then true else is_odd (n - 1)
  and is_odd n = if n = 0 then false else is_even (n - 1)

  $ test_valet examples/good/mutual_recursion.ml
  let rec is_even : int -> bool = fun n ->
    if n = 0 then true else is_odd (n - 1)
  and is_odd : int -> bool = fun n -> if n = 0 then false else is_even (n - 1)

Mixed arities in mutual recursion
----------------------------------

  $ cat examples/good/mixed_arities.ml
  val factorial : int -> int
  val factorial_acc : int -> int -> int
  let rec factorial n = factorial_acc n 1
  and factorial_acc n acc = if n <= 1 then acc else factorial_acc (n - 1) (n * acc)

  $ test_valet examples/good/mixed_arities.ml
  let rec factorial : int -> int = fun n -> factorial_acc n 1
  and factorial_acc : int -> int -> int = fun n acc ->
    if n <= 1 then acc else factorial_acc (n - 1) (n * acc)

Bad examples (should fail or be rejected)
==========================================

Val appearing after let (wrong order)
--------------------------------------

  $ cat examples/bad/val_after_let.ml
  (* val should not apply to a let that comes before it *)
  let x = 42
  val x : int

  $ test_valet examples/bad/val_after_let.ml
  let x : int = 42
  [BUG: val applied to let that comes before it!]

Val separated from let by another binding
------------------------------------------

  $ cat examples/bad/val_separated_from_let.ml
  (* val should only apply to immediately following let *)
  val x : int
  let y = 1
  let x = 42

  $ test_valet examples/bad/val_separated_from_let.ml
  let y = 1
  let x : int = 42
  [BUG: val x applied to second x, not immediately following let!]

Duplicate val declarations
---------------------------

  $ cat examples/bad/duplicate_val.ml
  (* Multiple val declarations for same name is ambiguous *)
  val x : int
  val x : float
  let x = 42

  $ test_valet examples/bad/duplicate_val.ml
  let x : float = 42
  [BUG: Last val declaration wins, should be an error!]

Shadowing case
--------------

  $ cat examples/bad/shadowing.ml
  (* The first val should not apply to the second x *)
  val x : int
  let x = 42

  let x = "hello"

  $ test_valet examples/bad/shadowing.ml
  let x : int = 42
  let x : int = "hello"
  [BUG: val applied to both x bindings due to shadowing!]

Val without matching let
-------------------------

  $ cat examples/bad/val_without_let.ml
  (* val without matching let *)
  val x : int
  val y : string
  let x = 42

  $ test_valet examples/bad/val_without_let.ml
  let x : int = 42
  [BUG: val y silently ignored, should warn or error!]

Local bindings
==============

Simple local binding
--------------------

  $ cat examples/good/local_simple.ml
  let val x : int in
  let x = 7 in
  x + 1

  $ test_valet examples/good/local_simple.ml
  let x : int = 7 in
  x + 1

Local binding with function
---------------------------

  $ cat examples/good/local_function.ml
  let val f : int -> int in
  let f x = x + 1 in
  f 5

  $ test_valet examples/good/local_function.ml
  let f : int -> int = fun x -> x + 1 in
  f 5

Mutually recursive local bindings
----------------------------------

  $ cat examples/good/local_mutual_recursion.ml
  let val is_even : int -> bool in
  let val is_odd : int -> bool in
  let rec is_even n = if n = 0 then true else is_odd (n - 1)
  and is_odd n = if n = 0 then false else is_even (n - 1) in
  is_even 4

  $ test_valet examples/good/local_mutual_recursion.ml
  let rec is_even : int -> bool = fun n ->
    if n = 0 then true else is_odd (n - 1)
  and is_odd : int -> bool = fun n ->
    if n = 0 then false else is_even (n - 1) in
  is_even 4

Nested local bindings
---------------------

  $ cat examples/good/local_nested.ml
  let val x : int in
  let x = 5 in
  let val y : int in
  let y = x + 1 in
  y * 2

  $ test_valet examples/good/local_nested.ml
  let x : int = 5 in
  let y : int = x + 1 in
  y * 2
