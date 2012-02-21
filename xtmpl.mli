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

(** Xml templating library. *)

type env
and callback = env -> (string * string) list -> tree list -> tree list
and tree =
    E of Xmlm.tag * tree list
  | T of string * (string * string) list * tree list
  | D of string

val env_empty : env
val env_add : string -> callback -> env -> env
val env_get : string -> env -> callback option

val string_of_env : env -> string

val tag_main : string
val tag_env : string

val string_of_xml : tree -> string
val xml_of_string : ?add_main:bool -> string -> tree

val env_add_att : string -> string -> env -> env

val eval_xml : env -> tree -> tree list
(*val eval_string : env -> string -> string*)

val apply : env -> string -> string
val apply_from_file : env -> string -> string
val apply_to_xmls : env -> tree list -> tree list
val apply_to_file : ?head:string -> env -> string -> string -> unit
val apply_string_to_file : ?head:string -> env -> string -> string -> unit

val get_arg : (string * string) list -> string -> string option
val string_of_args : (string * string) list -> string
val opt_arg : (string * string) list -> ?def:string -> string -> string

val env_of_list : ?env:env -> (string * callback) list -> env
