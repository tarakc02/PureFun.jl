module RedBlackTests
include("RedBlack.jl")


# setup {{{
using Test, .RedBlack
import .RedBlack.Red, .RedBlack.Black, .RedBlack.NE, .RedBlack.is_empty, .RedBlack.RB

function is_balanced(t::NE)
    black_height(t.left) == black_height(t.right)
end

black_height(::E{T}) where {T} = 0

function black_height(t::Red)
    bhl = black_height(t.left)
    bhr = black_height(t.right)
    bhl == bhr || throw("unbalanced subtree")
    return bhl
end

function black_height(t::NE)
    bhl = black_height(t.left)
    bhr = black_height(t.right)
    bhl == bhr || throw("unbalanced subtree")
    return 1 + bhl
end

is_bst(::E) = true
function is_bst(t)
    is_bst(t.left) || return false
    is_bst(t.right) || return false
    !is_empty(t.left) && t.left.elem >= t.elem && return false
    !is_empty(t.right) && t.right.elem <= t.elem && return false
    return true
end

is_redblack(::E) = true

is_black(::E) = true
is_black(::Black) = true
is_black(::Red) = false

function is_redblack(t::Red)
    is_black(t.left)  || return false
    is_black(t.right) || return false
    is_redblack(t.left) && is_redblack(t.right)
end

function is_redblack(t::Black)
    is_redblack(t.left) && is_redblack(t.right)
end

function array2tree(x::Array{T, 1}) where {T}
    tree = E{T}()
    for element in x
        tree = insert(tree, element)
    end
    return tree
end

function rand_tree(size)
    tree = E{Int64}()
    for x in rand(Int64, size)
        tree = insert(tree, x)
    end
    return tree
end
# }}}

@testset "insert elements" begin #{{{
    inorder = array2tree(collect(1:100))
    backward = array2tree(reverse(collect(1:100)))
    random = rand_tree(100)

    @test length(inorder) == 100
    @test length(backward) == 100
    @test length(random) == 100

    @test contains(inorder, 1)
    @test contains(inorder, 2)
    @test contains(inorder, 3)
    @test contains(inorder, 4)
    @test contains(inorder, 5)
    @test contains(inorder, 59)
    @test contains(inorder, 93)
    @test contains(inorder, 100)

    @test contains(backward, 1)
    @test contains(backward, 2)
    @test contains(backward, 3)
    @test contains(backward, 4)
    @test contains(backward, 5)
    @test contains(backward, 59)
    @test contains(backward, 93)
    @test contains(backward, 100)

    inorder2 = insert(inorder, 101)
    @test !contains(inorder, 101)
    @test contains(inorder2, 101)

    backward2 = insert(backward, 101)
    @test !contains(backward, 101)
    @test contains(backward2, 101)
end
# }}}

#@testset "range operators" begin
#    inorder = array2tree(collect(1:10))
#    backward = array2tree(reverse(collect(1:10)))
#
#    @test [el for el in between(inorder, 3, 5)] == [3, 4, 5]
#    @test [el for el in between(backward, 6, 9)] == [6, 7, 8, 9]
#end

@testset "maintain ordering" begin # {{{
    inorder = array2tree(collect(1:100))
    backward = array2tree(reverse(collect(1:100)))
    random = rand_tree(1000)

    @test is_bst(inorder)
    @test is_bst(backward)
    @test is_bst(random)
end
# }}}

#@testset "dictionary-style" begin #{{{
#    dict = E{Pair{Symbol, Int64}}()
#    dict = insert(dict, :a => 17)
#    dict = insert(dict, :b => 5)
#
#    @test contains(dict, :a)
#end
# }}}

@testset "maintain black balance" begin #{{{
    inorder = array2tree(collect(1:100))
    backward = array2tree(reverse(collect(1:100)))
    random = rand_tree(1000)

    @test is_balanced(inorder)
    @test is_balanced(backward)
    @test is_balanced(random)
end
# }}}

@testset "no red-red violations" begin #{{{
    inorder = array2tree(collect(1:100))
    backward = array2tree(reverse(collect(1:100)))
    random = rand_tree(1000)

    @test is_redblack(inorder)
    @test is_redblack(backward)
    @test is_redblack(random)
end
# }}}

#@testset "delete-min preserves invariants" begin
#    inorder = array2tree(collect(1:100))
#    backward = array2tree(reverse(collect(1:100)))
#    random = rand_tree(1000)
#
#    function test_del(tree)
#        m = minimum(tree)
#        t = delete_min(tree)
#
#        while !is_empty(t)
#            @test !contains(t, m)
#            @test  contains(tree, m)
#            @test is_redblack(t)
#            @test is_bst(t)
#            @test is_balanced(t)
#            m = minimum(t)
#            t = delete_min(t)
#        end
#    end
#
#
#    function find_problem(tree)
#        t = tree
#        while !is_empty(t)
#            t_new = delete_min(t);
#            try
#                is_balanced(t_new)
#            catch 
#                return t
#            end
#            t = t_new;
#        end
#    end
#
#    test_del(inorder)
#    test_del(backward)
#    test_del(random)
#end

#@testset "iteration" begin
#    function nattree(n)
#        tree = E{Int64}()
#        for element in 1:n
#            tree = insert(tree, element)
#        end
#        return tree
#    end
#
#    test = nattree(100);
#    @test all([x for x in test] .== 1:100)
#end

end
