using Pkg, Literate
Pkg.devdir("..")

Literate.markdown(joinpath(@__DIR__, "src/$(ARGS[1]).jl"),
                  joinpath(@__DIR__, "output/$(ARGS[1])");
                  name = "index",
                  flavor = Literate.CommonMarkFlavor(),
                  config = Dict("execute" => true))

