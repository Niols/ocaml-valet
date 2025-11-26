(* Polymorphic methods in objects *)
val obj : < m : 'a. 'a -> 'a >
let obj = object method m : 'a. 'a -> 'a = fun x -> x end
