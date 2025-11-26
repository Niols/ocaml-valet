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

Explicit universal quantification
----------------------------------

  $ cat examples/good/explicit_forall.ml
  (* Explicit universal quantification *)
  val id : 'a. 'a -> 'a
  let id x = x

  $ test_valet examples/good/explicit_forall.ml
  let id : 'a . 'a -> 'a = fun x -> x

Polymorphic methods in objects
-------------------------------

  $ cat examples/good/polymorphic_method.ml
  (* Polymorphic methods in objects *)
  val obj : < m : 'a. 'a -> 'a >
  let obj = object method m : 'a. 'a -> 'a = fun x -> x end

  $ test_valet examples/good/polymorphic_method.ml
  let obj : < m: 'a . 'a -> 'a   >  =
    object method m : 'a . 'a -> 'a= fun x -> x end

Let with existing type constraint
----------------------------------

  $ cat examples/good/let_with_existing_constraint.ml
  (* Val with let that already has type annotations *)
  val f : int -> int
  let f (x : int) : int = x + 1

  $ test_valet examples/good/let_with_existing_constraint.ml
  let f : int -> int = fun (x : int) : int-> x + 1

GADT function with locally abstract types
------------------------------------------

  $ cat examples/good/gadt_function.ml
  (* GADT function with locally abstract type in implementation *)
  type _ t = Int : int t | String : string t
  val show : 'a t -> string
  let show (type a) (x : a t) : string =
    match x with
    | Int -> "int"
    | String -> "string"

  $ test_valet examples/good/gadt_function.ml
  type _ t =
    | Int: int t 
    | String: string t 
  let show : 'a t -> string =
    fun (type a) (x : a t) : string->
      match x with | Int -> "int" | String -> "string"

External declaration (not treated as val)
------------------------------------------

  $ cat examples/good/external_not_val.ml
  (* External declarations should not be treated as vals *)
  external get_time : unit -> float = "caml_get_time"
  let get_time () = int_of_float (get_time ())

  $ test_valet examples/good/external_not_val.ml
  external get_time : unit -> float = "caml_get_time"
  let get_time () = int_of_float (get_time ())

Val with existing type constraint in pattern
---------------------------------------------

  $ cat examples/good/val_with_pattern_constraint.ml
  (* Val with pattern that already has constraint *)
  val f : int -> int
  val g : string -> string
  let ((f : int -> int), g) = ((fun x -> x + 1), (fun s -> s ^ "!"))

  $ test_valet examples/good/val_with_pattern_constraint.ml
  let (((f : int -> int) : int -> int), (g : string -> string)) =
    ((fun x -> x + 1), (fun s -> s ^ "!"))

Pattern binding (not yet supported)
------------------------------------

  $ cat examples/good/pattern_binding.ml
  (* Pattern binding with multiple vals - not yet supported *)
  val f : int -> int
  val g : string -> string
  let (f, g) = ((fun x -> x + 1), (fun s -> s ^ "!"))

  $ test_valet examples/good/pattern_binding.ml
  let ((f : int -> int), (g : string -> string)) =
    ((fun x -> x + 1), (fun s -> s ^ "!"))

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

Val with existing type constraint on let binding
-------------------------------------------------

  $ cat examples/bad/val_with_existing_constraint.ml
  (* Both val and let have type constraints - ambiguous *)
  val f : int -> int
  let f : int -> int = fun x -> x + 1

  $ test_valet examples/bad/val_with_existing_constraint.ml
  [%%ocaml.error
    "val declaration conflicts with existing type constraint on let binding. Remove one of the two, or rewrite into a pattern type constraint, eg. change `let f : t = \226\128\166` into `let (f : t) = \226\128\166`."]
  external f : int -> int
  let f : int -> int = fun x -> x + 1
  File "examples/bad/val_with_existing_constraint.ml", line 2, characters 0-18:
  2 | val f : int -> int
      ^^^^^^^^^^^^^^^^^^
  Error: val declaration conflicts with existing type constraint on let
         binding. Remove one of the two, or rewrite into a pattern type
         constraint, eg. change `let f : t = …` into `let (f : t) = …`.
  [2]

Pattern binding with explicit forall (OCaml syntax limitation)
---------------------------------------------------------------

  $ cat examples/bad/pattern_with_forall.ml
  (* Pattern binding with explicit universal quantification - not possible in OCaml *)
  val id : 'a. 'a -> 'a
  val add_one : int -> int
  let (id, add_one) = ((fun x -> x), (fun x -> x + 1))

  $ test_valet examples/bad/pattern_with_forall.ml
  let ((id : 'a . 'a -> 'a), (add_one : int -> int)) =
    ((fun x -> x), (fun x -> x + 1))
  File "examples/bad/pattern_with_forall.ml", line 4, characters 21-33:
  4 | let (id, add_one) = ((fun x -> x), (fun x -> x + 1))
                           ^^^^^^^^^^^^
  Error: This expression should not be a function, the expected type is
         'a. 'a -> 'a
  [2]
