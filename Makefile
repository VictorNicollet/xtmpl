#

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
	$(CP) xtmpl.cm* $(INSTALLDIR)

#####
clean:
	$(RM) *.cm* *.o *.annot

