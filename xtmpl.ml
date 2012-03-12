(*********************************************************************************)
(*                Xtmpl                                                          *)
(*                                                                               *)
(*    Copyright (C) 2012 Maxence Guesdon. All rights reserved.                   *)
(*                                                                               *)
(*    This program is free software; you can redistribute it and/or modify       *)
(*    it under the terms of the GNU General Public License as                    *)
(*    published by the Free Software Foundation; either version 2 of the         *)
(*    License, or any later version.                                             *)
(*                                                                               *)
(*    This program is distributed in the hope that it will be useful,            *)
(*    but WITHOUT ANY WARRANTY; without even the implied warranty of             *)
(*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              *)
(*    GNU Library General Public License for more details.                       *)
(*                                                                               *)
(*    You should have received a copy of the GNU General Public                  *)
(*    License along with this program; if not, write to the Free Software        *)
(*    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA                   *)
(*    02111-1307  USA                                                            *)
(*                                                                               *)
(*    As a special exception, you have permission to link this program           *)
(*    with the OCaml compiler and distribute executables, as long as you         *)
(*    follow the requirements of the GNU GPL in regard to all of the             *)
(*    software in the executable aside from the OCaml compiler.                  *)
(*                                                                               *)
(*    Contact: zoggy@bat8.org                                                    *)
(*                                                                               *)
(*********************************************************************************)

(** *)

(*c==v=[File.string_of_file]=1.0====*)
let string_of_file name =
  let chanin = open_in_bin name in
  let len = 1024 in
  let s = String.create len in
  let buf = Buffer.create len in
  let rec iter () =
    try
      let n = input chanin s 0 len in
      if n = 0 then
        ()
      else
        (
         Buffer.add_substring buf s 0 n;
         iter ()
        )
    with
      End_of_file -> ()
  in
  iter ();
  close_in chanin;
  Buffer.contents buf
(*/c==v=[File.string_of_file]=1.0====*)

(*c==v=[File.file_of_string]=1.1====*)
let file_of_string ~file s =
  let oc = open_out file in
  output_string oc s;
  close_out oc
(*/c==v=[File.file_of_string]=1.1====*)

module Str_map = Map.Make (struct type t = string let compare = compare end);;

type env = (env -> (string * string) list -> tree list -> tree list) Str_map.t
and callback = env -> (string * string) list -> tree list -> tree list
and tree =
    E of Xmlm.tag * tree list
  | T of string * (string * string) list * tree list
  | D of string


let env_empty = Str_map.empty;;
let env_add = Str_map.add;;
let env_get s env =
  try Some (Str_map.find s env)
  with Not_found -> None
;;

let rec fix_point ?(n=0) f x =
  (*
  let file = Printf.sprintf "/tmp/fixpoint%d.txt" n in
  file_of_string ~file x;
  *)
  let y = f x in
  if y = x then x else fix_point ~n: (n+1) f y
;;

let string_of_env env =
  String.concat ", " (Str_map.fold (fun s _ acc -> s :: acc) env [])
;;

let tag_main = "main";;
let tag_env = "env_";;
let att_defer = "defer_";;

let pad = "<?xml version=\"1.0\" encoding=\"UTF-8\"?> "
let pad_len = String.length pad;;

let string_of_xml tree =
  try
    let b = Buffer.create 256 in
    let output = Xmlm.make_output (`Buffer b) in
    let frag = function
    | E (tag, childs) -> `El (tag, childs)
    | T (tag, atts, childs) ->
        let tag = ("", tag) in
        let atts = List.map (fun (s,v) -> (("",s), v)) atts in
        `El ((tag, atts), childs)
    | D d -> `Data d
    in
    Xmlm.output_doc_tree frag output (None, tree);
    let s = Buffer.contents b in
    let len = String.length s in
    String.sub s pad_len (len - pad_len)
  with
    Xmlm.Error ((line, col), error) ->
      let msg = Printf.sprintf "Line %d, column %d: %s"
        line col (Xmlm.error_message error)
      in
      failwith msg
;;

let xml_of_string ?(add_main=true) s =
  let s =
    if add_main then
      Printf.sprintf "<%s>%s</%s>" tag_main s tag_main
    else
      s
  in
  try
    let input = Xmlm.make_input ~enc: (Some `UTF_8) (`String (0, s)) in
    let el tag childs = E (tag, childs)  in
    let data d = D d in
    let (_, tree) = Xmlm.input_doc_tree ~el ~data input in
    tree
  with
    Xmlm.Error ((line, col), error) ->
      let msg = Printf.sprintf "Line %d, column %d: %s\n%s"
        line col (Xmlm.error_message error) s
      in
      failwith msg
  | Invalid_argument e ->
      let msg = Printf.sprintf "%s:\n%s" e s in
      failwith msg
;;


let re_escape = Str.regexp "&\\(\\([a-z]+\\)\\|\\(#[0-9]+\\)\\);";;

let escape_ampersand s =
  let len = String.length s in
  let b = Buffer.create len in
  for i = 0 to len - 1 do
    match s.[i] with
      '&' when Str.string_match re_escape s i ->
        Buffer.add_char b '&'
    | '&' -> Buffer.add_string b "&amp;"
    | c -> Buffer.add_char b c
  done;
  Buffer.contents b
;;

let re_amp = Str.regexp_string "&amp;";;
let unescape_ampersand s = Str.global_replace re_amp "&" s;;

let env_add_att a v env =
  env_add a (fun _ _ _ -> [xml_of_string v]) env
;;


let rec eval_env env atts subs =
(*  prerr_endline
    (Printf.sprintf "env: subs=%s"
      (String.concat "" (List.map string_of_xml subs)));
*)
  let env = List.fold_left
    (fun acc ((_,s),v) ->
(*       prerr_endline (Printf.sprintf "env: %s=%s" s v);*)
       env_add_att s v acc)
    env atts
  in
  List.flatten (List.map (eval_xml env) subs)

and eval_xml env = function
| (D _) as xml -> [ xml ]
| other ->
    let (tag, atts, subs) =
      match other with
        D _ -> assert false
      | T (tag, atts, subs) ->
        (("", tag), List.map (fun (s,v) -> (("",s), v)) atts, subs)
      | E ((tag, atts), subs) -> (tag, atts, subs)
    in
    let f = function
      (("",s), v) ->
        let v2 = eval_string env (escape_ampersand v) in
        (*prerr_endline
          (Printf.sprintf "att: %s -> %s -> %s -> %s"
         v (escape_ampersand v) v2 (unescape_ampersand v2)
        );*)
        let v2 = unescape_ampersand v2 in
        (("", s), v2)
    | _ as att -> att
    in
    let atts = List.map f atts in
    let (defer,atts) = List.partition
      (function
       | (("",s), n) when s = att_defer ->
           (try ignore (int_of_string n); true
            with _ -> false)
       | _ -> false
      )
      atts
    in
    let defer =
      match defer with
        [] -> 0
      | ((_,_), n) :: _ -> int_of_string n
    in
    match tag with
      ("", t) when t = tag_env -> ((eval_env env atts subs) : tree list)
    | (uri, tag) ->
        match uri, env_get tag env with
        | "", Some f ->
            if defer > 0 then
              (* defer evaluation, evaluate subs first *)
              (
               let subs = List.flatten (List.map (eval_xml env) subs) in
               let att_defer = (("",att_defer), string_of_int (defer-1)) in
               let atts = att_defer :: atts in
               [ E (((uri, tag), atts), subs) ]
              )
            else
              (
               let xml = f env (List.map (fun ((_,s),v) -> (s,v)) atts) subs in
               List.flatten (List.map (eval_xml env) xml)
              )
              (* eval f before subs *)
        | _ ->
            let subs = List.flatten (List.map (eval_xml env) subs) in
            [ E (((uri, tag), atts), subs) ]

and eval_string env s =
  let xml = xml_of_string s in
  let f_main env atts subs = subs in
  let env = env_add tag_main f_main env in
  String.concat "" (List.map string_of_xml (eval_xml env xml))
;;

let apply env s = fix_point (eval_string env) s;;

let apply_from_file env file =
  let s = string_of_file file in
  apply env s
;;

let apply_to_xmls env l =
  List.flatten (List.map (eval_xml env) l)
;;

let apply_to_file ?head env file out_file =
  let s = apply_from_file env file in
  let s = match head with None -> s | Some h -> h^s in
  file_of_string ~file: out_file s
;;

let apply_string_to_file ?head env s out_file =
  let s = apply env s in
  let s = match head with None -> s | Some h -> h^s in
  file_of_string ~file: out_file s
;;

let get_arg args name =
  try Some (List.assoc name args)
  with Not_found -> None
;;

let string_of_args args =
  String.concat " " (List.map (fun (s,v) -> Printf.sprintf "%s=%S" s v) args)
;;

let opt_arg args ?(def="") name =
  match get_arg args name with None -> def | Some s -> s
;;


let env_of_list ?(env=env_empty) l =
  List.fold_left (fun env (name, f) -> env_add name f env) env l
;;

  