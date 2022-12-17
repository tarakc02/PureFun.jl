# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

.PHONY: all deps test docs showdocs

src := $(wildcard src/*.jl)
docindex := docs/build/index.html
docsrc := $(wildcard docs/src)

benchmarks: benchmark/output/dicts/index.md \
	benchmark/output/list-comparisons/index.md

all: $(docindex) test $(benchmarks)

$(docindex): $(src) docs/make.jl $(docsrc)
	julia --project=docs/ -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate()'
	julia --project=docs/ docs/make.jl

docs: $(docindex)

showdocs: $(docs)
	cd docs/build && python -m http.server --bind localhost

test: deps
	julia --project -e "using Pkg; Pkg.test()"

benchmark/output/%/index.md: benchmark/src/%.jl benchmark/runbenchmarks.jl
	julia --project=benchmark -e "using Pkg; Pkg.resolve(); Pkg.instantiate()"
	julia --project=benchmark -O3 benchmark/runbenchmarks.jl $*

deps: 
	julia --project -e "using Pkg; Pkg.resolve(); Pkg.instantiate()"
