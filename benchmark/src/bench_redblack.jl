module RedBlackBenchmarks

using ..PureFun
using ..BenchmarkTools

#=

Baselines: time to compare two keys, time to create a non-trivial tree

=#

function construct_tree(sorted)
    e = RedBlack.RB{eltype(sorted)}()
    l = RedBlack.Black(sorted[1], e, e)
    r = RedBlack.Black(sorted[3], e, e)
    RedBlack.Black(sorted[2], l, r)
end

@benchmark k1 < k2 setup=(k1=rand(Int); k2=rand(Int))
@benchmark x in tree setup=(tree = RedBlack.RB(rand(Int)); x=rand(Int))
@benchmark construct_tree([1,2,3])

# insertion
@benchmark insert(tree, x) setup=(tree=RedBlack.RB(rand(Int, 512)); x=rand(Int))
@benchmark insert(tree, x) setup=(tree=RedBlack.RB(rand(Int, 1024)); x=rand(Int))

@benchmark delete_min(tree) setup=tree=RedBlack.RB(rand(Int, 512))
@benchmark delete_min(tree) setup=tree=RedBlack.RB(rand(Int, 1024))
@benchmark delete_max(tree) setup=tree=RedBlack.RB(rand(Int, 512))
@benchmark delete_max(tree) setup=tree=RedBlack.RB(rand(Int, 1024))

@benchmark RedBlack.Black(x, RedBlack.E{Int}(), RedBlack.E{Int}()) setup=x=rand(Int)

@benchmark RedBlack.RB(x) setup=x=rand(Int)

@benchmark insert(tree, x) setup=(tree=RedBlack.RB(rand(Int, 1000)); x=rand(Int))
@benchmark insert(tree, x) setup=(tree=RedBlack.RB(1:1000); x=rand(Int))

@benchmark x in tree setup=(tree = RedBlack.RB(rand(Int, 10_000)); x=rand(Int))
@benchmark x in tree setup=(tree = RedBlack.RB(1:10_000); x=rand(Int))
@benchmark x in tree setup=(tree = RedBlack.RB(10_000:-1:1); x=rand(Int))

@benchmark minimum(tree) setup=tree = RedBlack.RB(rand(Int, 10))
@benchmark minimum(tree) setup = tree=RedBlack.RB(1:10)

@benchmark insert(tree, x) setup=(tree = RedBlack.RB(rand(Int, 1000)); x = rand(Int))
@benchmark delete_min(tree) setup=tree = RedBlack.RB(rand(Int, 1000))
@benchmark delete_max(tree) setup=tree = RedBlack.RB(rand(Int, 1000))

@benchmark delete_min(tree) setup = tree=RedBlack.RB(1:1000)
@benchmark delete_max(tree) setup = tree=RedBlack.RB(1:1000)
@benchmark delete(tree, 1000) setup = tree=RedBlack.RB(1:1000)
@benchmark delete(tree, 1) setup = tree=RedBlack.RB(1:1000)

@benchmark delete(tree, minimum(tree)) setup=tree = RedBlack.RB(rand(Int, 1_000))
@benchmark delete(tree, 1) setup = tree=RedBlack.RB(1:1_000)
@benchmark delete_max(tree) setup = tree=RedBlack.RB(1:1_000)

@benchmark delete_max(tree) setup=(tree = RedBlack.RB(rand(Int, 1_000)); x=rand(Int))
@benchmark delete(tree, 0) setup=(tree = insert(RedBlack.RB(rand(Int, 1_000)), 0))

end

