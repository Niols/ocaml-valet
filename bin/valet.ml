(* Force the Valet module to be loaded to register the transformation *)
let () = ignore (Valet.SMap.empty)

let () = Ppxlib.Driver.standalone ()
