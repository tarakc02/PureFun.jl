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

Literate.markdown(joinpath(@__DIR__, "src/estimating-pi.jl"),
                  joinpath(@__DIR__, "src/generated");
                  config = Dict("execute" => true))

Literate.markdown(joinpath(@__DIR__, "src/balanced-parentheses.jl"),
                  joinpath(@__DIR__, "src/generated");
                  config = Dict("execute" => true))

Literate.markdown(joinpath(@__DIR__, "src/taxicab.jl"),
                  joinpath(@__DIR__, "src/generated");
                  config = Dict("execute" => true))

Literate.markdown(joinpath(@__DIR__, "src/suffixes.jl"),
                  joinpath(@__DIR__, "src/generated");
                  config = Dict("execute" => true))


push!(LOAD_PATH,"../src/")
makedocs(sitename="PureFun.jl",
         repo = "https://github.com/tarakc02/PureFun.jl/blob/main/{path}#{line}",
         pages = [
            "index.md",
            "Lists" => "lists.md",
            "Queues/Deques" => "queues.md",
            "Heaps" => "heaps.md",
            "Dictionaries" => "dicts.md",
            "Streams" => "generated/streams.md",
            "Small size optimizations" => "contiguous.md",
            "Examples" => [
                "Estimating π" => "generated/estimating-pi.md",
                "Balanced Parentheses" => "generated/balanced-parentheses.md",
                "Ramanujan (taxicab) numbers" => "generated/taxicab.md",
                "Generating Suffixes" => "generated/suffixes.md"
               ],
            "Reference" => "reference.md",
        ])

deploydocs(
    repo = "github.com/tarakc02/PureFun.jl.git",
)
