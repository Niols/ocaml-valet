(* GADT function with locally abstract type in implementation *)
type _ t = Int : int t | String : string t
val show : 'a t -> string
let show (type a) (x : a t) : string =
  match x with
  | Int -> "int"
  | String -> "string"
