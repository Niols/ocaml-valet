# Valet

An OCaml preprocessor allowing to declare types from `let`-bindings with a
preceeding `val` declaration, “the Haskell way”.

## Example

When a `val` declaration and a `let` binding follow each other at top-level,
Valet will merge them into one `let` binding with a type constraint. For
instance:

```ocaml
val add : int -> int -> int
let add x y = x + y

(* gets changed into: *)

let add : int -> int -> int = fun x y -> x + y
```

Several `val` declarations can be attached to one `let` binding of multiple
values. This is useful in particular for mutually recursive functions. For
instance:

```ocaml
val factorial : int -> int
val factorial_acc : int -> int -> int

let rec factorial n = factorial_acc n 1
and factorial_acc n acc = if n <= 1 then acc else factorial_acc (n - 1) (n * acc)

(* gets changed into: *)

let rec factorial : int -> int = fun n -> factorial_acc n 1
and factorial_acc : int -> int -> int = fun n acc -> if n <= 1 then acc else factorial_acc (n - 1) (n * acc)
```

For more examples, see [test/valet.t](test/valet.t), which is more comprehensive
and is kept in sync by our CI.

## Usage

Add Valet as a preprocessor in your `dune` file:

```lisp
(executable
 (name my_program)
 (preprocess (pps valet)))
```

If you are curious, the library comes as a standalone executable, `valet`, which
will consume a file and print the OCaml result.

## Limitations

The main limitation, at this point, is that Valet only works for top-level
declarations, and is not available for local bindings. There are some other more
subtle limitations; for instance, it does not behave well when types are
universally quantified and multiple values are bound at once, eg.:

```ocaml
val id : 'a. 'a -> 'a
val add_one : int -> int

let (id, add_one) = ((fun x -> x), (fun x -> x + 1))
```

will fail, while

```ocaml
val id : 'a. 'a -> 'a

let id = fun x -> x
```

and

```ocaml
val add_one : int -> int
val add_one_f : float -> float

let (add_one, add_one_f) = ((fun x -> x + 1), (fun x -> x +. 1.))
```

will both behave as expected.
