(* Force the Valet module to be loaded to register the transformation *)
let () = ignore Valet.impl

let () = Ppxlib.Driver.standalone ()
