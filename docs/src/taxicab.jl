using PureFun
using PureFun: Pairing

#=

[Taxicab numbers](https://en.wikipedia.org/wiki/Taxicab_number) are numbers
that can be expressed as the sum of cubes in two different ways. In this
exercise we'll create an iterator over taxicab numbers less than `k`. We do
this by generating pairs of integers and ordering them by the sum of their
cubes, and then iterate through them in order looking for adjacent pairs with
the same sum of cubes. We use a custom
[ordering](https://docs.julialang.org/en/v1/base/sort/#Alternate-orderings) to
order a heap by the sum of cubes.

=#

sum_of_cubes(x,y) = x^3 + y^3
sum_of_cubes(pair) = sum_of_cubes(pair[1], pair[2]);

function taxi(k)
    all_pairs = distinct_pairs(k)
    ordered_pairs = Pairing.Heap(all_pairs,
                                 Base.Order.By(sum_of_cubes))
    consecutive_matches(ordered_pairs)
end

#=

We still need to implement the underlying iterators `distinct_pairs`, which
generates pairs of integers, and `consecutive matches`, which scans an iterator
that's already ordered for pairs of duplicates:

=#

distinct_pairs(k) = ((p,q) for (p,q) in Iterators.product(1:k, 1:k) if p < q)
adjacent_pairs(it) = zip(it, Iterators.drop(it, 1));

function consecutive_matches(pair_stream)
    (
     (pair1,pair2) for (pair1,pair2) in adjacent_pairs(pair_stream)
     if sum_of_cubes(pair1) == sum_of_cubes(pair2)
    )
end

# The results:

for t in taxi(75)
    println(sum_of_cubes(t[1]), ": ", t[1], " ", t[2], " :", sum_of_cubes(t[2]))
end
