open Ppxlib
open Ast_builder.Default

(** Add a type constraint to a [let]-binding. *)
let add_type_constraint (typ : core_type) (binding : value_binding) : value_binding =
  {binding with pvb_constraint = Some (Pvc_constraint {locally_abstract_univars = []; typ})}

(** Returns the one element in a list, and fails if there are none or multiple. *)
let unsingleton = function [x] -> x | _ -> failwith "unsingleton"

(** Return the name of a let-binding, assuming it is a simple [let <name> =]. *)
(* FIXME: handle more cases *)
let binding_name = function
  | {pvb_pat = {ppat_desc = Ppat_var {txt = name; _}; _}; _} -> name
  | _ -> failwith "binding_name"

(** Merge a list of [val] statements into the [let]-binding that directly
    follows them. *)
let merge_vals_let ~loc vals rec_flag bindings =
  let () =
    let binding_names = List.map binding_name bindings in
    List.iter
      (fun (name, (loc, _)) ->
        if not (List.mem name binding_names) then
          Location.raise_errorf ~loc "val declaration is unused by the following let binding"
      )
      vals
  in
  unsingleton @@
  pstr_value_list ~loc rec_flag @@
  List.map
    (fun binding ->
      match List.assoc_opt (binding_name binding) vals with
      | None -> binding
      | Some (_, typ) -> add_type_constraint typ binding
    )
    bindings

(** Go through the whole file, collect [val] statements and merge them into the
    [let]-binding that directly follows them, using {!merge_vals_let}. *)
let impl =
  let rec impl (vals : (string * (location * core_type)) list) : structure_item list -> structure_item list = function
    | item :: items ->
      (
        match item.pstr_desc with
        | Pstr_primitive {pval_name = {txt = name; _}; pval_type; pval_prim; pval_attributes; pval_loc = loc} when pval_prim = [] ->
          (
            (* val binding *)
            if List.mem_assoc name vals then
              Location.raise_errorf ~loc "multiple val declarations for the same name"
            else if pval_attributes <> [] then
              Location.raise_errorf ~loc "don't know what to do with attributes for this"
            else
              impl ((name, (loc, pval_type)) :: vals) items
          )
        | Pstr_value (rec_flag, bindings) ->
          (
            (* let binding *)
            merge_vals_let ~loc: item.pstr_loc vals rec_flag bindings :: impl [] items
          )
        | _ ->
          (
            (* other structure *)
            match vals with
            | [] -> item :: impl [] items
            | (_, (loc, _)) :: _ ->
              (* Report at the location of the last `val`. *)
              (* FIXME: better would be to report at a location encompassing
                 all the `val`, and add in the error message the location of
                 the first non-`val`. *)
              Location.raise_errorf ~loc "val declarations must be immediately followed by a let binding"
          )
      )
    | [] ->
      (
        match vals with
        | [] -> []
        | (_, (loc, _)) :: _ -> Location.raise_errorf ~loc "Unused val declarations at end of structure"
      )
  in
  impl []

let () =
  Driver.register_transformation "valet" ~impl
