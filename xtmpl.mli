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
