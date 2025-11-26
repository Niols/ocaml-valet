(* Both val and let have type constraints - ambiguous *)
val f : int -> int
let f : int -> int = fun x -> x + 1
