(* Pattern binding with multiple vals - not yet supported *)
val f : int -> int
val g : string -> string
let (f, g) = ((fun x -> x + 1), (fun s -> s ^ "!"))
