open Ppxlib
open Ast_builder.Default

(* Map from value names to their types *)
module SMap = Map.Make(String)

(* Extract val declarations from structure items *)
let extract_val_declarations
    (items : structure_item list)
    : core_type SMap.t
  =
  List.fold_left
    (fun map item ->
      match item.pstr_desc with
      | Pstr_primitive vd -> SMap.add vd.pval_name.txt vd.pval_type map
      | _ -> map
    )
    SMap.empty
    items

(* Transform a value_binding by adding a type constraint *)
let add_type_constraint
  (typ : core_type)
  (vb : value_binding)
  : value_binding
= {vb with
  pvb_constraint =
  Some (Pvc_constraint {locally_abstract_univars = []; typ})
}

let unsingleton = function [x] -> x | _ -> failwith "unsingleton"

(* Transform a let binding using collected val declarations *)
let merge_vals_let ~loc vals rec_flag bindings =
  unsingleton @@
  pstr_value_list ~loc rec_flag @@
  List.map
    (function
      | {pvb_pat = {ppat_desc = Ppat_var {txt = name; _}; _}; _} as binding ->
        (
          match SMap.find_opt name vals with
          | None -> binding
          | Some typ -> add_type_constraint typ binding
        )
      | _ -> assert false
    )
    bindings

let impl =
  let rec impl (vals : core_type SMap.t) : structure_item list -> structure_item list = function
    | item :: items ->
      (
        match item.pstr_desc with
        | Pstr_primitive {pval_name = {txt = name; _}; pval_type; pval_prim; pval_attributes; pval_loc = loc} when pval_prim = [] ->
          (* val binding *)
          if SMap.mem name vals then
            Location.raise_errorf ~loc "multiple val declarations for the same name"
          else if pval_attributes <> [] then
            Location.raise_errorf ~loc "don't know what to do with attributes for this"
          else
            impl (SMap.add name pval_type vals) items
        | Pstr_value (rec_flag, bindings) ->
          (* let binding *)
          merge_vals_let ~loc: item.pstr_loc vals rec_flag bindings :: impl SMap.empty items
        | _ ->
          (* other structure *)
          if not (SMap.is_empty vals) then (* we cannot have seen a val *)
            Location.raise_errorf ~loc: item.pstr_loc "val declarations must be immediately followed by a let binding"
          else
            item :: impl SMap.empty items
      )
    | [] ->
      if not (SMap.is_empty vals) then (* we cannot have vals remaining *)
        Location.raise_errorf "Unused val declarations at end of structure"
      else
          []
  in
  impl SMap.empty

let () =
  Driver.register_transformation "valet" ~impl
