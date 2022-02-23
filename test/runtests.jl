include("../src/PureFun.jl")
using .PureFun
using Test

@test [] == detect_ambiguities(Core, PureFun)
@test [] == detect_ambiguities(Base, PureFun)

tests = [
    "linked_list",
    "stream"
   ]

if length(ARGS) > 0
    tests = ARGS
end

@testset "PureFun" begin

for t in tests
    #fp = joinpath(".", "test_$t.jl")
    fp = joinpath(dirname(@__FILE__), "test_$t.jl")
    println("$fp ...")
    include(fp)
end

end
