# vim: set ts=8 sts=0 sw=8 si fenc=utf-8 noet:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

.PHONY: all test benchmarks showdocs

src := $(wildcard src/*.jl)
docs := docs/build/index.html

all: $(docs) test

$(docs): $(src)
	julia --project=docs docs/make.jl

showdocs: $(docs)
	cd docs/build && python -m http.server --bind localhost

test:
	julia --project -e "using Pkg; Pkg.test()"

benchmarks: 
	julia --project=benchmark benchmark/runbenchmarks.jl
