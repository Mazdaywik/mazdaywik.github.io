DOTS=$(wildcard *.dot)
PNGS=$(DOTS:%.dot=%.png)
DOTCMD="C:\Program Files (x86)\Graphviz2.38\bin\dot.exe"

all: $(PNGS)

%.png: %.dot
	$(DOTCMD) -Tpng $< -o$@
