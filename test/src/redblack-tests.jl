module RedBlackTests

using PureFun
using PureFun.RedBlack
using Test

# setup {{{
import .RedBlack.Red, .RedBlack.Black, .RedBlack.NE, .RedBlack.E,  .RedBlack.RB

is_balanced(t::E) = true

function is_balanced(t::NE)
    black_height(t.left) == black_height(t.right)
end

black_height(::E) = 0

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
    !isempty(t.left) && t.left.elem >= t.elem && return false
    !isempty(t.right) && t.right.elem <= t.elem && return false
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

rand_tree(size) = RB(rand(Int64, size))

# }}}

@testset "insert elements" begin #{{{
    inorder = RedBlack.RB(1:100)
    backward = RedBlack.RB(reverse(1:100))
    random = RedBlack.RB(rand(Int64, 100))

    @test length(inorder) == 100
    @test length(backward) == 100
    @test length(random) == 100

    @test 1 in inorder
    @test 2 in inorder
    @test 3 in inorder
    @test 4 in inorder
    @test 5 in inorder
    @test 59 in inorder
    @test 93 in inorder
    @test 100 in inorder

    @test 1 in backward
    @test 2 in backward
    @test 3 in backward
    @test 4 in backward
    @test 5 in backward
    @test 59 in backward
    @test 93 in backward
    @test 100 in backward

    inorder2 = RedBlack.insert(inorder, 101)
    @test 101 ∉ inorder
    @test 101 ∈ inorder2

    backward2 = RedBlack.insert(backward, 101)
    @test 101 ∉ backward
    @test 101 ∈ backward2
end
# }}}

@testset "maintain ordering" begin # {{{
    inorder = RedBlack.RB(1:100)
    backward = RedBlack.RB(reverse(1:100))
    random = RedBlack.RB(rand(Int64, 100))

    @test is_bst(inorder)
    @test is_bst(backward)
    @test is_bst(random)
end
# }}}

@testset "maintain black balance" begin #{{{
    inorder = RB(1:100)
    backward = RB(reverse(1:100))
    random = RB(rand(Int64, 100))

    @test is_balanced(inorder)
    @test is_balanced(backward)
    @test is_balanced(random)
end
# }}}

@testset "no red-red violations" begin #{{{
    inorder = RB(1:100)
    backward = RB(reverse(1:100))
    random = rand_tree(1000)

    @test is_redblack(inorder)
    @test is_redblack(backward)
    @test is_redblack(random)
end
# }}}

@testset "delete-min preserves invariants" begin # {{{
    inorder = RB(1:100)
    backward = RB(reverse(1:100))
    random = rand_tree(1000)

    function test_del(tree)
        m = minimum(tree)
        t = delete_min(tree)

        while !isempty(t)
            @test m ∉ t
            @test m ∈ tree
            @test is_redblack(t)
            @test is_bst(t)
            @test is_balanced(t)
            m = minimum(t)
            t = delete_min(t)
        end
    end

    test_del(inorder)
    test_del(backward)
    test_del(random)
end

# }}}

@testset "delete-max preserves invariants" begin # {{{
    inorder = RB(1:100)
    backward = RB(reverse(1:100))
    random = rand_tree(1000)

    function test_del(tree)
        m = maximum(tree)
        t = delete_max(tree)

        while !isempty(t)
            @test m ∉ t
            @test m ∈ tree
            @test is_redblack(t)
            @test is_bst(t)
            @test is_balanced(t)
            m = maximum(t)
            t = delete_max(t)
        end
    end

    test_del(inorder)
    test_del(backward)
    test_del(random)
end

# }}}

@testset "arbitrary deletion preserves invariants" begin # {{{
    seed = Set(rand(Int16, 200))
    tree = RB(seed)
    t = tree

    function test_del(tree)
        for s in seed
            t = delete(tree, s)
            @test s ∉ t
            @test s ∈ tree
            @test is_redblack(t)
            @test is_bst(t)
            @test is_balanced(t)
            tree = t
        end
    end

    test_del(tree)
end

# }}}

@testset "iteration" begin # {{{
    @test all(collect(RB(1:100) .== 1:100))
end
# }}}

end
