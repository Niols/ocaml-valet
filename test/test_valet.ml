(* Basic test for valet PPX *)

let test_basic () = Alcotest.(check pass) "basic" () ()

let () =
  let open Alcotest in
  run "valet" [("basic", [test_case "basic" `Quick test_basic])]
