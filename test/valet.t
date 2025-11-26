Test the valet PPX transformations
==================================

Setup
-----

  $ test_valet() { ocamlc -ppx 'valet --as-ppx' -dsource -c "$1" 2>&1; }

Good examples
=============

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
  let rec is_even : int -> bool =
    fun n -> if n = 0 then true else is_odd (n - 1)
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
  and factorial_acc : int -> int -> int =
    fun n acc -> if n <= 1 then acc else factorial_acc (n - 1) (n * acc)

Bad examples (should fail or be rejected)
=========================================

Val appearing after let (wrong order)
--------------------------------------

  $ cat examples/bad/val_after_let.ml
  (* val should not apply to a let that comes before it *)
  let x = 42
  val x : int

  $ test_valet examples/bad/val_after_let.ml
  [%%ocaml.error "Unused val declarations at end of structure"]
  let x = 42
  external x : int
  File "examples/bad/val_after_let.ml", line 3, characters 0-11:
  3 | val x : int
      ^^^^^^^^^^^
  Error: Unused val declarations at end of structure
  [2]

Val separated from let by another structure item
------------------------------------------------

  $ cat examples/bad/val_separated_from_let.ml
  (* val should only apply to immediately following let *)
  val x : int
  open Stdlib
  let x = 42

  $ test_valet examples/bad/val_separated_from_let.ml
  [%%ocaml.error
    "val declarations must be immediately followed by a let binding"]
  external x : int
  open Stdlib
  let x = 42
  File "examples/bad/val_separated_from_let.ml", line 2, characters 0-11:
  2 | val x : int
      ^^^^^^^^^^^
  Error: val declarations must be immediately followed by a let binding
  [2]

Duplicate val declarations
---------------------------

  $ cat examples/bad/duplicate_val.ml
  (* Multiple val declarations for same name is ambiguous *)
  val x : int
  val x : float
  let x = 42

  $ test_valet examples/bad/duplicate_val.ml
  [%%ocaml.error "multiple val declarations for the same name"]
  external x : int
  external x : float
  let x = 42
  File "examples/bad/duplicate_val.ml", line 3, characters 0-13:
  3 | val x : float
      ^^^^^^^^^^^^^
  Error: multiple val declarations for the same name
  [2]

Shadowing case
--------------

  $ cat examples/bad/shadowing.ml
  (* The first val should not apply to the second x *)
  val x : int
  let x = 42
  let x = "hello"

  $ test_valet examples/bad/shadowing.ml
  let x : int = 42
  let x = "hello"

Val without matching let
-------------------------

  $ cat examples/bad/val_without_let.ml
  (* val without matching let *)
  val x : int
  val y : string
  let x = 42

  $ test_valet examples/bad/val_without_let.ml
  [%%ocaml.error "val declaration is unused by the following let binding"]
  external x : int
  external y : string
  let x = 42
  File "examples/bad/val_without_let.ml", line 3, characters 0-14:
  3 | val y : string
      ^^^^^^^^^^^^^^
  Error: val declaration is unused by the following let binding
  [2]
