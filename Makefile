#################################################################################
#                Xtmpl                                                          #
#                                                                               #
#    Copyright (C) 2012 Maxence Guesdon. All rights reserved.                   #
#                                                                               #
#    This program is free software; you can redistribute it and/or modify       #
#    it under the terms of the GNU General Public License as                    #
#    published by the Free Software Foundation; either version 2 of the         #
#    License, or any later version.                                             #
#                                                                               #
#    This program is distributed in the hope that it will be useful,            #
#    but WITHOUT ANY WARRANTY; without even the implied warranty of             #
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              #
#    GNU Library General Public License for more details.                       #
#                                                                               #
#    You should have received a copy of the GNU General Public                  #
#    License along with this program; if not, write to the Free Software        #
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA                   #
#    02111-1307  USA                                                            #
#                                                                               #
#    As a special exception, you have permission to link this program           #
#    with the OCaml compiler and distribute executables, as long as you         #
#    follow the requirements of the GNU GPL in regard to all of the             #
#    software in the executable aside from the OCaml compiler.                  #
#                                                                               #
#    Contact: zoggy@bat8.org                                                    #
#                                                                               #
#################################################################################

INCLUDES=-I +xmlm
COMPFLAGS=$(INCLUDES) -annot -rectypes
OCAMLPP=

OCAMLC=ocamlc.opt -g
OCAMLOPT=ocamlopt.opt -g
OCAMLLIB:=`$(OCAMLC) -where`
OCAMLDOC=ocamldoc.opt

INSTALLDIR=$(OCAMLLIB)

RM=rm -f
CP=cp -f
MKDIR=mkdir -p

all: byte opt
byte: xtmpl.cmo
opt: xtmpl.cmx

xtmpl.cmx: xtmpl.cmi xtmpl.ml
	$(OCAMLOPT) -c $(COMPFLAGS) xtmpl.ml

xtmpl.cmo: xtmpl.cmi xtmpl.ml
	$(OCAMLC) -c $(COMPFLAGS) xtmpl.ml

xtmpl.cmi: xtmpl.mli
	$(OCAMLC) -c $(COMPFLAGS) $<

##########
.PHONY: doc
doc:
	$(MKDIR) doc
	$(OCAMLDOC) $(INCLUDES) xtmpl.mli -d doc -html

##########
install:
	$(MKDIR) $(INSTALLDIR)
	$(CP) xtmpl.cm* xtmpl.o $(INSTALLDIR)

#####
clean:
	$(RM) *.cm* *.o *.annot

