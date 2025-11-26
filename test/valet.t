Test the valet PPX transformations
=================================

Setup
-----

  $ test_valet() { ocamlc -ppx 'valet --as-ppx' -dsource -c "$1" 2>&1; }

Simple function
---------------

  $ cat examples/simple_function.ml
  val add_one : int -> int
  let add_one x = x + 1

  $ test_valet examples/simple_function.ml
  let add_one : int -> int = fun x -> x + 1

Multiple parameters
-------------------

  $ cat examples/multiple_params.ml
  val add : int -> int -> int
  let add x y = x + y

  $ test_valet examples/multiple_params.ml
  let add : int -> int -> int = fun x y -> x + y

Value (no parameters)
---------------------

  $ cat examples/value.ml
  val forty_two : int
  let forty_two = 42

  $ test_valet examples/value.ml
  let forty_two : int = 42

Mutually recursive functions
-----------------------------

  $ cat examples/mutual_recursion.ml
  val is_even : int -> bool
  val is_odd : int -> bool
  let rec is_even n = if n = 0 then true else is_odd (n - 1)
  and is_odd n = if n = 0 then false else is_even (n - 1)

  $ test_valet examples/mutual_recursion.ml
  let rec is_even : int -> bool = fun n ->
    if n = 0 then true else is_odd (n - 1)
  and is_odd : int -> bool = fun n -> if n = 0 then false else is_even (n - 1)

Mixed arities in mutual recursion
----------------------------------

  $ cat examples/mixed_arities.ml
  val factorial : int -> int
  val factorial_acc : int -> int -> int
  let rec factorial n = factorial_acc n 1
  and factorial_acc n acc = if n <= 1 then acc else factorial_acc (n - 1) (n * acc)

  $ test_valet examples/mixed_arities.ml
  let rec factorial : int -> int = fun n -> factorial_acc n 1
  and factorial_acc : int -> int -> int = fun n acc ->
    if n <= 1 then acc else factorial_acc (n - 1) (n * acc)
