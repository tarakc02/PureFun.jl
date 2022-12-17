using Pkg, Literate
Pkg.devdir("..")

Literate.markdown(joinpath(@__DIR__, "src/list-comparisons.jl"),
                  joinpath(@__DIR__, "output/list-comparisons");
                  flavor = Literate.CommonMarkFlavor(),
                  config = Dict("execute" => true))

