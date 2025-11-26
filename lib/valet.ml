open Ppxlib
open Ast_builder.Default

(** Returns the one element in a list, and fails if there are none or multiple. *)
let unsingleton = function [x] -> x | _ -> failwith "unsingleton"

(** Map over variables in a pattern, calling its argument for each [Ppat_var]. *)
let rec map_vars_in_pattern (f : string Asttypes.loc -> pattern_desc) (pat : pattern) : pattern =
  let desc =
    match pat.ppat_desc with
    | Ppat_var name -> f name
    | Ppat_tuple pats -> Ppat_tuple (List.map (map_vars_in_pattern f) pats)
    | Ppat_constraint (p, ct) -> Ppat_constraint (map_vars_in_pattern f p, ct)
    | Ppat_alias (p, name) -> Ppat_alias (map_vars_in_pattern f p, name)
    | Ppat_construct (lid, arg) ->
      let arg' = Option.map (fun (lbls, p) -> (lbls, map_vars_in_pattern f p)) arg in
      Ppat_construct (lid, arg')
    | Ppat_record (fields, closed) ->
      let fields' = List.map (fun (lid, p) -> (lid, map_vars_in_pattern f p)) fields in
      Ppat_record (fields', closed)
    | Ppat_or (p1, p2) ->
      Ppat_or (map_vars_in_pattern f p1, map_vars_in_pattern f p2)
    | _ -> pat.ppat_desc
  in
    {pat with ppat_desc = desc}

(** Returns the variables from a pattern. *)
let vars_in_pattern pat =
  let vars = ref [] in
  let _ = map_vars_in_pattern (fun var -> vars := var.txt :: !vars; Ppat_var var) pat in
  List.rev !vars

(** Add type constraints from [vals] to a binding. If the pattern is a simple
    variable, uses [pvb_constraint]. Otherwise, uses [Ppat_constraint] on all
    variables in the pattern. *)
let add_type_constraints_to_binding (vals : (string * (location * core_type)) list) (binding : value_binding) : value_binding =
  match binding.pvb_pat.ppat_desc with
  | Ppat_var {txt = name; _} ->
    (
      (* For simple variable binding, eg. [let f = ...], we use pvb_constraint. *)
      match List.assoc_opt name vals with
      | None -> binding
      | Some (loc, typ) ->
        if binding.pvb_constraint <> None then
          Location.raise_errorf
            ~loc
            "val declaration conflicts with existing type constraint on let binding. \
             Remove one of the two, or rewrite into a pattern type constraint, \
             eg. change `let f : t = …` into `let (f : t) = …`.";
        {binding with
          pvb_constraint = Some (Pvc_constraint {locally_abstract_univars = []; typ})
        }
    )
  | _ ->
    (* For more complex pattern binding, fall back on using Ppat_constraint on
       each variable. This will work but only on smaller types; for instance, no
       universal quantification anymore. *)
    {binding with
      pvb_pat =
      map_vars_in_pattern
        (fun var ->
          match List.assoc_opt var.txt vals with
          | None -> Ppat_var var
          | Some (_, typ) -> Ppat_constraint (ppat_var ~loc: var.loc var, typ)
        )
        binding.pvb_pat
    }

(** Merge a list of [val] statements into the [let]-binding that directly
    follows them. *)
let merge_vals_let ~loc vals rec_flag bindings =
  (* check that the names in [vals] are included in those bound by [bindings] *)
  let binding_names = List.concat_map (fun b -> vars_in_pattern b.pvb_pat) bindings in
  List.iter
    (fun (name, (loc, _)) ->
      if not (List.mem name binding_names) then
        Location.raise_errorf ~loc "val declaration is unused by the following let binding"
    )
    vals;
  (* generate a new binding with type constraints where possible *)
  unsingleton @@
  pstr_value_list ~loc rec_flag @@
  List.map (add_type_constraints_to_binding vals) bindings

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
