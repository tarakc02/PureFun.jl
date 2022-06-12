# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

.PHONY: all deps test benchmarks docs showdocs

src := $(wildcard src/*.jl)
docindex := docs/build/index.html
docsrc := $(wildcard docs/src)

all: $(docindex) test

$(docindex): $(src) docs/make.jl $(docsrc)
	julia --project=docs -e "using Pkg; Pkg.resolve(); Pkg.instantiate()"
	julia --project=docs docs/make.jl

docs: $(docindex)

showdocs: $(docs)
	cd docs/build && python -m http.server --bind localhost

test:
	julia --project -e "using Pkg; Pkg.test()"

benchmarks: 
	julia --project=benchmark -e "using Pkg; Pkg.resolve(); Pkg.instantiate()"
	julia --project=benchmark benchmark/runbenchmarks.jl

deps: 
	julia --project -e "using Pkg; Pkg.resolve(); Pkg.instantiate()"
