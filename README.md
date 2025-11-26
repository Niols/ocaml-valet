# Valet

A PPX rewriter for OCaml that enables Haskell-style type annotations.

## Example

```ocaml
val add : int -> int -> int
let add x y = x + y

(* Transformed to: *)
let add : int -> int -> int = fun x y -> x + y
```

For more examples, see [test/valet.t](test/valet.t).

## Usage

Add `valet` as a preprocessor in your `dune` file:

```lisp
(executable
 (name my_program)
 (preprocess (pps valet)))
```
