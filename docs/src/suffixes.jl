using PureFun
using PureFun.Linked: List
using Plots, BenchmarkTools

#=

> Exercise 2.1: Write a function `suffixes` of type List{α} -> List{List{α}}
> that takes a list `xs` and returns a list of all the suffixes of `xs` in
> decreasing order of length. For example: 
> 
> suffixes([1,2,3,4]) = [[1,2,3,4], [2,3,4], [3,4], [4], []]
> 
> Show that the resulting list of suffixes can be generated in $\mathcal{O}(n)$
> time and represented in $\mathcal{O}(n)$ space

=#

# ## Set up a test case

test = [1,2,3,4];
expected_output = [[1,2,3,4], [2,3,4], [3,4], [4], Int[]];


# ## The `suffixes` function

#=

Our strategy is: we'll traverse the input from the right. We'll generate the
suffixes in ascending order and successively place each one at the top of our
solution, so that at the end we have the desired output:

=#

suffixes(l) = foldr( add_suffix, l, init = empty_suffixlist(eltype(l)) );

#=

We still have to define `add_suffix` and `empty_suffixlist`.

For each element, `add_suffix` creates the next suffix by adding the element to
the front of the most recently generated suffix, and then pushes the new suffix
on to the top of the suffix list.

=#
add_suffix(x, sufs) = (x ⇀ sufs[1]) ⇀ sufs;

# For the base case, we initialize a list containing just the empty suffix:
empty_suffixlist(::Type{T}) where T = List{T}() ⇀ List{List{T}}();

# ## Confirm the solution is valid

suffixes(test)
@assert all(collect.(suffixes(test)) .== expected_output)

# ## Time and space complexity

# First, we generate some data for the experiments:

input_lists = List.(1:k for k in 10:10:500);
input_lengths = length.(input_lists);
input_sizes = Base.summarysize.(input_lists);

# Now, we measure the time and the space used to generate suffixes:

suffix_times = map(input_lists) do l
    @belapsed suffixes($l) evals=1 samples=5
end;

suffix_sizes = map(suffixes.(input_lists)) do s
    Base.summarysize(s)
end;

#=

Each call to `pushfirst` allocates a copy of the element being pushed, plus a
new pointer to the remainder of the list. On my machine, a pointer is 8 bytes.
So when working with lists of `Int` (aka `Int64`), each `next_suffix` requires
a copy of an `Int` (8-bytes) and a pointer, for a total of 16 bytes. From
there, `add_suffix` requires a pointer to the newly created suffix, plus a
pointer to the previously generated suffixes, for another 16 bytes. Altogether,
generating a list of all suffixes of a list of Int64 of length N requires 32
bytes per original element, plus the fixed overhead of the empty suffix at the end:

=#

init_size = Base.summarysize(empty_suffixlist(Int));
@assert all(@. suffix_sizes == (32input_lengths + init_size))

#=

Based on that, clearly our solution satisfies the $\mathcal{O}(n)$ space
requirement.

Similarly, the time required to generate the suffixes is observably linear in
the length of the input:

=#

plot(input_lengths, 1e9*suffix_times,
     seriestype = :scatter,
     xlabel = "# of input elements",
     ylabel = "nanoseconds",
     title = "Time to generate all suffixes of a list",
     legend = false)
