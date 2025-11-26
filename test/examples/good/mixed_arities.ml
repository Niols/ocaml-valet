val factorial : int -> int
val factorial_acc : int -> int -> int
let rec factorial n = factorial_acc n 1
and factorial_acc n acc = if n <= 1 then acc else factorial_acc (n - 1) (n * acc)
