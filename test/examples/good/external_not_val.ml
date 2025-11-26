(* External declarations should not be treated as vals *)
external get_time : unit -> float = "caml_get_time"
let get_time () = int_of_float (get_time ())
