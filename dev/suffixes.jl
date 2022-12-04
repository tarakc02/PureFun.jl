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

input_lists = List.(1:k for k in 25:25:500);
input_lengths = length.(input_lists);
input_sizes = Base.summarysize.(input_lists);

# Now, we measure the time and the space used to generate suffixes:

suffix_times = map(input_lists) do l
    @belapsed suffixes($l) evals=1 samples=2
end;

suffix_sizes = map(suffixes.(input_lists)) do s
    Base.summarysize(s)
end;

#=

Our solution satisfies the $\mathcal{O}(n)$ space requirement:

=#

plot(input_lengths, suffix_sizes/1000,
     seriestype = :scatter,
     xlabel = "# of input elements",
     ylabel = "kB",
     title = "Space required to represent all suffixes of a list",
     legend = false)

#=

Similarly, the time required to generate the suffixes is approximately linear
in the length of the input:

=#

plot(input_lengths, 1e6*suffix_times,
     seriestype = :scatter,
     xlabel = "# of input elements",
     ylabel = "μs",
     title = "Time to generate all suffixes of a list",
     legend = false)
