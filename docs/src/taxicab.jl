using PureFun

#=

[Taxicab numbers](https://en.wikipedia.org/wiki/Taxicab_number) are numbers
that can be expressed as the sum of cubes in two different ways. In this
exercise we'll create an iterator over taxicab numbers less than `k`. We do
this by generating pairs of integers and ordering them by the sum of their
cubes. `PFHeaps` are parameterized by the type of the elements, and an
[`Ordering`](https://docs.julialang.org/en/v1/base/sort/#Alternate-orderings)
(will default to `Forward`). So we just need to fill up a heap that orders
pairs by their sum of cubes, and then iterate through them in order looking for
adjacent pairs with the same sum of cubes:

=#

function gen_taxi_nums(k)
    taxi_order = Base.Order.By(sum_of_cubes)
    pairs_in_order = PureFun.Pairing.Heap(distinct_pairs(k), taxi_order)
    (
     (pair1,pair2) for (pair1,pair2) in adjacent_pairs(pairs_in_order)
     if sum_of_cubes(pair1) == sum_of_cubes(pair2)
    )
end

sum_of_cubes(x,y) = x^3 + y^3
sum_of_cubes(pair) = sum_of_cubes(pair[1], pair[2]);

#=

For the underlying iterators:

=#

distinct_pairs(k) = ((p,q) for (p,q) in Iterators.product(1:k, 1:k) if p < q)
adjacent_pairs(it) = zip(it, Iterators.drop(it, 1));

# and we're done: 

for t in gen_taxi_nums(50)
    println(sum_of_cubes(t[1]), ": ", t[1], " ", t[2], " :", sum_of_cubes(t[2]))
end
