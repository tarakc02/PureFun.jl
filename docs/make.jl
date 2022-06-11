using Pkg
Pkg.devdir("..")
using Documenter, PureFun, Literate

# build any literate files to markdown
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
