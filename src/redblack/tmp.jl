include("src/RedBlack.jl")
using .RedBlack

using BenchmarkTools    
using Random: randstring
#using DataStructures: SortedSet, startof

# helpers {{{
function randstring_tree(size)
    tree = E{String}()
    for i in 1:size
        x = randstring("AB", 80)
        tree = insert(tree, x)
    end
    return tree
end

function randint_tree(size)
    tree = E{Int64}()
    for i in 1:size
        x = rand(Int64)
        tree = insert(tree, x)
    end
    return tree
end

#function randstring_set(size)
#    set = SortedSet{String}()
#    for i in 1:size
#        x = randstring("AB", 80)
#        push!(set, x)
#    end
#    return set
#end
# }}}

tree = randstring_tree(10_00);
dm1 = delete_min(tree) |> delete_min;
dm2 = RedBlack.delete_min2(tree) |> delete_min;

all([contains(dm2, x) for x in between(dm1, "", "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ")])

tree = randstring_tree(100);
treea = insert(tree, randstring("AB", 80));
Base.summarysize(tree)
Base.summarysize(treea)
Base.summarysize([tree, treea])
set = randstring_set(1_000);

# setup to get baselines {{{
@benchmark k1 < k2 setup=(k1=randstring("AB", 80); k2=randstring("AB", 80))
@benchmark k1 < k2 setup=(k1=rand(Int64); k2=rand(Int64))

@benchmark tree.left.right setup=(tree=randstring_tree(25))

@benchmark isequal(k1, k2) setup=(k1=randstring("AB", 80); k2=randstring("AB", 80))

@benchmark contains(tree, x) setup=(tree = E{String}(); x=randstring("ABCD", 40))
@benchmark x in set setup=(set = SortedSet{String, Base.Order.ForwardOrdering}(); x=randstring("ABCD", 40))

@benchmark contains(tree, x) setup=(tree = randstring_tree(1); x=randstring("AB", 80))
@benchmark RedBlack.contains2(tree, x) setup=(tree = randstring_tree(1); x=randstring("AB", 80))

@benchmark x in set setup=(set = randstring_set(1); x=randstring("AB", 80))

# }}}

@benchmark contains(tree, x) setup=(tree = randstring_tree(1); x=randstring("AB", 80))
@benchmark RedBlack.contains2(tree, x) setup=(tree = randstring_tree(1); x=randstring("AB", 80))

@benchmark insert(tree, x) setup=(tree = randstring_tree(1); x=randstring("AB", 80))
@benchmark x in set setup=(set = randstring_set(1); x=randstring("AB", 80))

function f()
    tree = randstring_tree(256)
    x = randstring("AB", 80)
    @code_warntype contains(tree, x)
end


b = Base.Order.ord(isless, x -> x.first, nothing)
struct CO{O <: Base.Order.Ordering} end

c = CO{Base.Order.ForwardOrdering}()

CO(o) = CO{typeof(o)}
d = CO(b)
(typeof())
f(x::CO{O}) where {O <: Base.Order.Ordering}= O()
f(d)

struct bloop
    x::Nothing
end

constr(::O) where {O <: Base.Order.Ordering} = O()

@benchmark contains(tree, x) setup=(tree = randstring_tree(256); x=randstring("AB", 80))
@benchmark insert(tree, x) setup=(tree = randstring_tree(1_000); x=randstring("AB", 80))

@benchmark tree.elem < x setup=(tree = randstring_tree(256); x=randstring("AB", 80))
@benchmark RedBlack.smaller(tree, x) setup=(tree = randstring_tree(256); x=randstring("AB", 80))

@benchmark contains(tree, x) setup=(tree = randstring_tree(512); x=randstring("AB", 80))

@benchmark contains(tree, x) setup=(tree = randstring_tree(1024); x=randstring("AB", 80))
@benchmark RedBlack.contains2(tree, x) setup=(tree = randstring_tree(1024); x=randstring("AB", 80))

@benchmark contains(tree, x) setup=(tree = randstring_tree(2048); x=randstring("AB", 80))


@benchmark insert(tree, x) setup=(tree = randstring_tree(1_000); x=randstring("AB", 80))
@benchmark insert(tree, x) setup=(tree = randint_tree(10_000); x=rand(Int64))
@benchmark insert!(set, x) setup=(set = randstring_set(10_000); x=randstring("AB", 80))


tree = randstring_tree(1_000_000);
tree2 = insert(tree, randstring("AB", 80));
Base.summarysize(tree)
Base.summarysize(tree2)
Base.summarysize((tree, tree2)) - Base.summarysize(tree2)

@benchmark insert(tree, x) setup=(tree = randstring_tree(0); x=randstring("AB", 80))
@benchmark insert(tree, x) setup=(tree = randstring_tree(1); x=randstring("AB", 80))
@benchmark insert(tree, x) setup=(tree = randstring_tree(2); x=randstring("AB", 80))
@benchmark insert(tree, x) setup=(tree = randstring_tree(4); x=randstring("AB", 80))

@benchmark insert(tree, x) setup=(tree = randstring_tree(128); x=randstring("AB", 80))
@benchmark insert(tree, x) setup=(tree = randstring_tree(256); x=randstring("AB", 80))
@benchmark insert(tree, x) setup=(tree = randstring_tree(512); x=randstring("AB", 80))
@benchmark insert(tree, x) setup=(tree = randstring_tree(1024); x=randstring("AB", 80))

# to compare to original benchmarks
@benchmark insert(tree, x) setup=(tree = randint_tree(100_000); x=rand(Int64))

@benchmark insert(tree, x) setup=(tree = randstring_tree(4096); x=randstring("AB", 80))
@benchmark insert!(set, x) setup=(set = randstring_set(4096); x=randstring("AB", 80))

@benchmark insert(tree, x) setup=(tree = randstring_tree(25_000); x=randstring("AB", 80))
@benchmark insert!(set, x) setup=(set = randstring_set(25_000); x=randstring("AB", 80))

@benchmark insert(tree, x) setup=(tree = randstring_tree(100_000); x=randstring("AB", 80))
@benchmark insert!(set, x) setup=(set = randstring_set(100_000); x=randstring("AB", 80))

#const bigtree = randstring_tree(1_000_000);
const bigtree = randint_tree(1_000_000);

# record: 
@time const test = randstring_tree(10_000_000);
@time settest = randstring_set(10_000_000)

@benchmark insert($test, x) setup=(x=randstring("AB", 80))
@benchmark delete_min($test)
#@benchmark insert!($settest, x) setup=(x=randstring("AB", 80))

@benchmark contains($test, x) setup=(x=randstring("AB", 80))
@benchmark x in $settest setup=(x=randstring("AB", 80))

@benchmark minimum($test)
@benchmark first($settest)

@benchmark delete_min(tree) setup=(tree=randstring_tree(1_000))
@benchmark delete_min(tree) setup=(tree=randstring_tree(10_000))

tree = randstring_tree(25);
RedBlack.delete_min2(tree)

@benchmark contains(tree, x) setup=(tree = randstring_tree(10_000); x=randstring("AB", 80))
@benchmark x in set setup=(set = randstring_set(10_000); x=randstring("AB", 80))
@benchmark first(set) setup=(set=randstring_set(100_000))
@benchmark minimum(tree) setup=(tree=randstring_tree(100_000))
@benchmark RedBlack.minimum2($tree1)

@benchmark insert($tree1, x) setup=(x=randstring("ABCD", 40))
@benchmark delete_min($tree1)
@benchmark delete_min2($tree1)


### iteration
#

@benchmark iterate(x) setup=(x=randstring_tree(100_000))
@benchmark iterate(x, state) setup=(x = randstring_tree(100_000); (min, state) = iterate(x))

@benchmark minimum(x) setup=(x=randstring_tree(1_000))
@benchmark insert(tree, x) setup=(tree = randstring_tree(1_000); x=randstring("AB", 80))

@benchmark iterate(x) setup=(x=randstring_tree(10_000))
@benchmark delete_min(x) setup=(x=randstring_tree(10_000))
@benchmark insert(tree, x) setup=(tree = randstring_tree(10_000); x=randstring("AB", 80))
@benchmark contains(tree, x) setup=(tree = randstring_tree(10_000); x=randstring("AB", 80))
@benchmark minimum(x) setup=(x=randstring_tree(10_000))
