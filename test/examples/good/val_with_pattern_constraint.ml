(* Val with pattern that already has constraint *)
val f : int -> int
val g : string -> string
let ((f : int -> int), g) = ((fun x -> x + 1), (fun s -> s ^ "!"))
