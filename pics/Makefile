DOTS=$(wildcard *.dot)
PNGS=$(DOTS:%.dot=%.png)

all: $(PNGS)

%.png: %.dot
	"C:\Program Files (x86)\Graphviz2.38\bin\dot.exe" -Tpng $< -o$@
