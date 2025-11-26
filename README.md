# Valet

A PPX rewriter for OCaml that enables Haskell-style type annotations.

## Overview

Valet allows you to write separate `val` declarations before `let` bindings, similar to Haskell's style. The PPX transforms these into inline type annotations.

## Syntax

### Simple Functions

```ocaml
val foo : int -> int
let foo x = x + 1

(* Transformed to: *)
let foo : int -> int = fun x -> x + 1
```

### Multiple Parameters

```ocaml
val add : int -> int -> int
let add x y = x + y

(* Transformed to: *)
let add : int -> int -> int = fun x y -> x + y
```

### Values (no parameters)

```ocaml
val x : int
let x = 42

(* Transformed to: *)
let x : int = 42
```

### Mutually Recursive Functions

```ocaml
val is_even : int -> bool
val is_odd : int -> bool
let rec is_even n =
  if n = 0 then true else is_odd (n - 1)
and is_odd n =
  if n = 0 then false else is_even (n - 1)

(* Transformed to: *)
let rec is_even : int -> bool = fun n ->
  if n = 0 then true else is_odd (n - 1)
and is_odd : int -> bool = fun n ->
  if n = 0 then false else is_even (n - 1)
```

## Usage

Add `valet` as a preprocessor in your `dune` file:

```lisp
(executable
 (name my_program)
 (preprocess (pps valet)))
```

## Build

```bash
dune build
```

## Test

```bash
dune test
```

## Development

This project uses Nix flakes for development. Enter the development shell with:

```bash
nix develop
```

Or use direnv to automatically load the environment:

```bash
direnv allow
```
