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

(** Xml templating library. 

    Runs through an XML {!type:tree} and alters it using {!type:callback} rules
    provided by the {!type:env} environment. 

    A complete description of the templating rules is available in the templating
    engine section below. 
*)

type env
and callback = env -> (string * string) list -> tree list -> tree list
and tree =
    E of Xmlm.tag * tree list
  | T of string * (string * string) list * tree list (** Convenient notation for
							 XML elements, without 
							 having to specify the 
							 namespace as in Xmlm.tag
						     *)
  | D of string

(** {2 Environment} 
    
    An {!type:env} is a string-to-{!type:callback} associative map. In addition
    to basic manipulation functions, the functions {!val:env_add_att} and
    {!val:env_of_list} provide convenient shortcuts for common operations. 

    The environments are immutable, all mutating operations return new 
    environments. 
*)

(** An environment that contains no bindings.
*)
val env_empty : env

(** Add a binding to an environment. 

    [env_add "double" (fun _ _ xml -> xml @ xml)] binds the key
    string ["double"] to a callback that doubles an XML subtree. 

    If the same key was already bound, the previous binding is 
    replaced. 
*) 
val env_add : string -> callback -> env -> env

(** Get a binding from an environment. 

    If the binding is not found, returns [None]. 
*)
val env_get : string -> env -> callback option

(** String representation of all the keys in the environment. *)
val string_of_env : env -> string

(** Bind a callback that returns some XML. 

    The most frequent operation performed by a callback is to return a
    constant XML subtree. This convenience function lets you provide
    the XML subtree as a string. 

    [env_add_att "logo" "<img src=\"logo.png\"/>" env] binds the key
    "logo" to a callback that returns an XHTML image tag. 

    Note that the provided XML is automatically wrapped in the
    {!val:tag_main} tag, which will cause the corresponding 
    templating rules to be applied to it 
*)
val env_add_att : string -> string -> env -> env

(** Add several bindings at once. 

    This convenience function saves you the effort of calling 
    {!val:env_add} several times yourself. 

    [env_of_list ~env:env [ k1, f1 ; k2, f2 ]] is equivalent to 
    [env_add k2 f2 (env_add k1 f1 env)]. 

    @param env The environment to which bindings are added. If 
    not provided, {!val:env_empty} is used. 
*)
val env_of_list : ?env:env -> (string * callback) list -> env

(** {2 XML Manipulation} *)

(** The main tag, currently ["main"]. 

    Used by {!val:env_add_att}, {!val:xml_of_string} and, most importantly, 
    by the {!val:apply} functions. 
*)
val tag_main : string

(** The environment tag, currently ["env_"].
    
    See the template rules in the templating engine section below for more 
    information about this tag. 
*)
val tag_env : string

(** Outputs an XML string. 

    Does not include the initial [<?xml ... ?>]. 
*)
val string_of_xml : tree -> string

(** Parses a string as XML.
    
    @param add_main if true, adds [<main>..</main>] around the string 
    (see {!val:tag_main}). 
    @raise Failure when a parsing error occurs, includes the source string. 
*)
val xml_of_string : ?add_main:bool -> string -> tree

(** {2 Templating engine} 

    These functions apply one of two variants of the templating engine. 
    The first variant, used by {!val:eval_xml} and {!val:apply_to_xmls}, 
    applies one iteration of the templating rules, while the second variant,
    used by {!val:apply}, {!val:apply_from_file}, {!val:apply_to_file} and
    {!val:apply_string_to_file}, applies as many iterations as necessary
    to reach a fixpoint.

    {b I.} A single iteration descends recursively into the XML tree. If an
    element (without a namespace) appears in the environment, then the 
    environment callback is applied to its attributes and children.

    {i Example}: consider the following XML: 

    {v <album author="Rammstein" name="Reise, Reise">
  <track>Los</track>
  <track>Mein Teil</track>
</album> v}

    This would look for a callback bound to ["album"] in the environment
    and call it using [callback env ["author","Rammstein";"name","Reise, Reise"] xml] 
    where [env] is the current environment and [xml] represents the 
    two child [ <track>..</track> ] elements. 

    {b II.} The callback returns a new list of elements that is used 
    instead of the old element. 

    {i Example}: assuming that [env_add "x2" (fun _ _ xml -> xml @ xml)],
    then [<x2>A</x2>] is rewritten as [AA].

    {b III.} The engine then recursively descends into those replacement
    elements (this means that a poorly conceived rule set may well never 
    terminate). 

    {i Example}: [<x2><x2>A</x2></x2>] is first rewritten as 
    [<x2>A</x2><x2>A</x2>], and then as [AAAA].

    {b IV.} The [env_] and [main] elements (see {!val:tag_env} 
    and {!val:tag_main}) are a special case: both are automatically 
    replaced with their children (as if their callback was
    [(fun _ _ xml -> xml)]). 

    First difference, [main] is only available in the second 
    templating engine variant (so, it is not available in {!val:eval_xml} 
    and {!val:apply_to_xmls}) but it may be manually defined or overriden. 

    Second difference, [env_] effectively changes the environment
    used when processing its children by adding the bindings defined by
    its arguments (using {!val:env_add_att}, hence the name). 

    {i Example}: [<env_ a="&lt;b&gt;A&lt;/b&gt;"><a/></env_>] is
    replaced by [<a/>], which in turn is replaced by 
    [<b>A</b>]. 

    {b V.} If an element has a [defer_] attribute (that is greater
    than zero), then it is not processed and the attribute is decremented
    by one, and the processing recursively applies to its children. 

    {i Example}: [<x2 defer_="1"><x2>A</x2></x2>] is rewritten as
    [<x2 defer_="0">AA</x2>]. Applying the template engine on a 
    {b second} iteration would rewrite this to [AAAA]. 
*)

(** Apply {b one} iteration of the rules to a piece of XML. 

    See above for how an iteration is applied. 
*) 
val eval_xml : env -> tree -> tree list

(*val eval_string : env -> string -> string*)

(** Applies as many iterations as necessary to a piece of XML (represented
    as an unparsed string) to reach a fixed point. 

    See above for how an iteration is applied. 
*)
val apply : env -> string -> string

(** As {!val:apply}, but reads the XML from a file. *)
val apply_from_file : env -> string -> string

(** As {!val:eval_xml}, but applies to a list. *)
val apply_to_xmls : env -> tree list -> tree list

(** As {!val:apply_from_file}, but writes the result back to a file. 

    For instance, [apply_to_file env "source.xml" "desc.xml"].

    @param head Prepend this string to the XML that is output
    to the file. By default, nothing is prepended. 
*)
val apply_to_file : ?head:string -> env -> string -> string -> unit

(** As {!val:apply_to_file}, but reds the XML from a string instead
    of a file. 
*)
val apply_string_to_file : ?head:string -> env -> string -> string -> unit

(** {2 Utilities} 

    Several useful functions when workin with XML. 
*)

(** Finds a binding in an associative list. 
    
    This performs the same as [List.assoc], but returns an optional string
    instead of raising [Not_found].
*)
val get_arg : (string * string) list -> string -> string option

(** A string representation of an argument list. 

    [string_of_args ["a","x";"b","y"]] returns [a="x" b="y"]. Note that 
    the argument names are output verbatim, but the argument values are
    escaped with the [%S] format. 
*)
val string_of_args : (string * string) list -> string

(** Finds a binding in an associative list, or returns a default. 
    
    This performs the same as [List.assoc], but returns the provided
    default value instead of raising [Not_found].

    @param def Default value, returned for missing bindings. If not
    provided, an empty string is used. 
*)
val opt_arg : (string * string) list -> ?def:string -> string -> string
