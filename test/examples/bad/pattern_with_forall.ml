(* Pattern binding with explicit universal quantification - not possible in OCaml *)
val id : 'a. 'a -> 'a
val add_one : int -> int
let (id, add_one) = ((fun x -> x), (fun x -> x + 1))
