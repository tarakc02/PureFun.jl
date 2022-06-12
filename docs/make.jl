using Pkg
Pkg.devdir("..")
using Documenter, PureFun, Literate

#=
build any literate files to markdown note: it would be nice not to have
generated files in `src`, but not sure how to configure Documenter to get that
to work, see:

  - https://github.com/JuliaDocs/Documenter.jl/issues/551
  - https://github.com/JuliaDocs/Documenter.jl/issues/1208
  - https://github.com/JuliaDocs/Documenter.jl/pull/552

so working with what we have. src/generated is .gitignored
=#
Literate.markdown(joinpath(@__DIR__, "src/streams.jl"),
                  joinpath(@__DIR__, "src/generated");
                  config = Dict("execute" => true))

push!(LOAD_PATH,"../src/")
makedocs(sitename="PureFun.jl",
         pages = [
            "index.md",
            "Lists" => "lists.md",
            "Streams" => "generated/streams.md"
        ])
