using PureFun, PureFun.HashMaps, PureFun.Tries
using Test, BenchmarkTools, Random

#=

## Setup: testing dictionary implementations for correctness

In the following essay, we'll construct a variety of immutable dictionary
types. We start with some basic tests to convince ourselves that the
dictionaries work as expected

=#

nstrings(n) = collect(randstring(rand(8:15)) for _ in 1:n)
randpairs(n) = (k => v for (k,v) in zip(nstrings(n), rand(Int, n)))

function test_dicttype(D)
    @testset "basic tests for $D" begin

        kvs = randpairs(100)
        testdict = D(kvs)

        @test all(testdict[p.first] == p.second for p in kvs)
        @test empty(testdict) |> isempty

        e = D{String,String}()
        @test isempty(e)

        d1 = setindex(e, "world", "hello")
        @test length(d1) == 1
        @test d1["hello"] == "world"
    end
    return nothing
end;

#=

Microbenchmarks will be noisy when run on the documentation server. In the
essay below, instead of running the benchmarking code, I'll report my results
from running the code locally. But I'm including the benchmarking code used
here for those who want to follow along. Note that actual performance of any
dictionary will depend on the size and distribution of keys, the tests here are
not meant to be comprehensive, but are meant to illustrate the concepts and
tradeoffs explored below.

=#

function bench_dicttype(D, n)
    kvs = randpairs(n)
    testdict = D(kvs)
    ks = collect(kv.first for kv in kvs)
    search_hit  = @benchmark $testdict[k] setup=k=rand($ks)
    search_miss = @benchmark get($testdict, "nonexisting key", -1)
    (size = n,
     search_hit_ns  = round(Int, median(search_hit).time),
     search_miss_ns = round(Int, median(search_miss).time))
end;

#=

As a reference point, we see how `Base.Dict` looks:

```julia
julia> bench_dicttype(Dict, 10)
(size = 10, search_hit_ns = 12, search_miss_ns = 11)

julia> bench_dicttype(Dict, 100)
(size = 100, search_hit_ns = 11, search_miss_ns = 11)

julia> bench_dicttype(Dict, 100_000)
(size = 100000, search_hit_ns = 12, search_miss_ns = 11)

julia> bench_dicttype(Dict, 1_000_000)
(size = 1000000, search_hit_ns = 12, search_miss_ns = 18)
```

## Introduction: hashmaps

Exercise 10.11 of *Purely Functional Data Structures* describes a *hashmap* (or
hashtable) as a nested dictionary, an outer dictionary that maps *approximate*
keys to inner dictionaries keyed by *exact* keys. We complete the definition by
specifying a *hash* function that converts exact keys to approximate keys. For
example, in C++ the
[`std::unordered_map`](https://en.cppreference.com/w/cpp/container/unordered_map)
uses `std::hash` as a hash function that maps input keys to integers, an array
as the *approximate* dictionary (think of an array as a dictionary with integer
keys), and a linked list as the *exact* dictionary.

[`PureFun.HashMaps.@hashmap`](@ref) constructs new dictionary types by
assembling hashmaps from specified components:

=#

const RBDict = PureFun.RedBlack.RBDict{Base.Order.ForwardOrdering}

@hashmap(RedBlackHashMap,
         approx   = RBDict,
         exact    = PureFun.Association.List,
         hashfunc = hash)

#=

`hashfunc` is optional, and is set to
[`Base.hash`](https://docs.julialang.org/en/v1/base/base/#Base.hash) by
default.[^hashfuncs]

We now test and benchmark `RedBlackHashMap`:

=#

test_dicttype(RedBlackHashMap)

#=

Though the resulting benchmarks are still impressive, we can see that search
times slow down as the collection gets larger.

```julia
julia> bench_dicttype(RedBlackHashMap, 10)
(size = 10, search_hit_ns = 31, search_miss_ns = 16)

julia> bench_dicttype(RedBlackHashMap, 100)
(size = 100, search_hit_ns = 35, search_miss_ns = 24)

julia> bench_dicttype(RedBlackHashMap, 100_000)
(size = 100000, search_hit_ns = 69, search_miss_ns = 59)

julia> bench_dicttype(RedBlackHashMap, 1_000_000)
(size = 1000000, search_hit_ns = 81, search_miss_ns = 71)
```

Alas, anyone who's been using `Base.Dict` will have become accustomed to
constant time lookups and inserts, while the `RedBlackHashMap` requires
$\log_{2}n$ time. Can we do better?

=#

#=

[^hashfuncs]: We can specify different hash functions to achieve a variety of
              behaviors. For example, in [near duplicate
              detection](https://hrdag.org/2013/03/07/hrdags-record-de-duplication/),
              we utilize *locality-sensitive* hash functions, which hash
              "similar" input values to the same output value, for
              domain-specific definitions of "similar." Given a
              [soundex](https://en.wikipedia.org/wiki/Soundex) implementation,
              we could expand `RedBlackHashMap` into a dictionary of named
              tuples indexed into "blocks" of similar records:

    ```julia
    @hashmap(SoundexDict,
             approx   = RedBlackHashMap,
             exact    = RedBlackHashMap,
             hashfunc = x -> soundex(x.lastname))
    ```

## Improving on $\mathcal{O}(\log_{2}n)$

[`PureFun.Contiguous.bitmap`](@ref) allows us to construct fast and compact
dictionaries over integer keys, with lookups requiring a single memory access
plus a couple of hardware-optimized bit-shift operations. The resulting
dictionary is nearly as fast at indexing integer keys as a raw `Base.Vector`,
but is sparse, requiring just one bit of extra storage for each key that is not
present. The drawback is that we are limited to small keys. Still, we can
construct a tiny version of C++'s
[`std::unordered_map`](https://en.cppreference.com/w/cpp/container/unordered_map)[^addone]:

=#

const BitMap = PureFun.Contiguous.bitmap(64)

@hashmap(BitMapHashMap,
         approx   = BitMap,
         exact    = PureFun.Association.List,
         hashfunc = x -> 1 + hash(x) % 64)

test_dicttype(BitMapHashMap)

#=

Once again I ran the benchmarks locally:

```julia
julia> bench_dicttype(BitMapHashMap, 10)
(size = 10, search_hit_ns = 23, search_miss_ns = 11)

julia> bench_dicttype(BitMapHashMap, 100)
(size = 100, search_hit_ns = 24, search_miss_ns = 18)

julia> bench_dicttype(BitMapHashMap, 100_000)
(size = 100000, search_hit_ns = 4171, search_miss_ns = 11417)
```

[^addone]: When taking the modulo to convert the hash to a valid key for the bitmap
      we have to add 1, since the bitmaps expect keys in the range $[1,2^{n}]$
      rather than $[0,2^{n}-1]$

For small collections, the `BitMapHashMap` provides lookup times comparable to
`Base.Dict`, but if our collection grows much at all, lookup times devolve to
linear in the number of elements, as the [pigeonhole
principle](https://en.wikipedia.org/wiki/Pigeonhole_principle) pushes most of
the search down to the linked lists. We're calculating a full 64-bit hash, but
we lose most of that information when we squeeze it into a BitMap that can only
hold small numbers. What we need is a way to generalize the performance
benefits of the `BitMap` to larger keys.

## Tries: chaining together smaller dictionaries

Chapter 10, ($\S{10.3.1}$) of *Purely Functional Data Structures* introduces
another dictionary type, the [trie](https://en.wikipedia.org/wiki/Trie). It's
described as "a multiway tree where each edge is labelled with a character." In
PureFun.jl, tries can be used not just with strings, but with any type of key
that decomposes into a sequence of simpler keys.

Lookup and insertion times in tries are independent of the number of keys, and
are instead linear in the length of keys. Tries in PureFun.jl use path
compression, so in practice looking up well-distributed keys requires visiting
a small number of nodes regardless of key length.

When implementing a trie, a critical question:

> ... is how to represent edges leaving a node. Ordinarily, we would represent
> the children of a multiway node as a list of trees, but here we also need to
> represent the edge labels. Depending on the choice of base type and the
> expected density of the trie, we might represent the edges leaving a node as a
> vector, an association list, a binary search tree, or even, if the base type is
> itself a list or a string, another trie! We abstract away from the particular
> representation of these edge maps ...

[`PureFun.Tries.@trie`](@ref) constructs new trie types given an `edgemap`
type.

=#

@trie(RedBlackTrie,
      edgemap = PureFun.RedBlack.RBDict{Base.Order.ForwardOrdering})

test_dicttype(RedBlackTrie)

#=

We can use any key type that decomposes into a sequence of simpler keys, for
example we can use a trie to organize integer sequences stored as linked lists:

=#

const ∅ = PureFun.Linked.List{Int}()

RedBlackTrie((1 ⇀ 2 ⇀ ∅     => "inorder",
              3 ⇀ 2 ⇀ 1 ⇀ ∅ => "reversed",
              2 ⇀ 1 ⇀ 3 ⇀ ∅ => "random"))

#=

Because we started with already randomized string keys (which we expect to be
nicely distributed), the `RedBlackTrie` can shine without need for a hash
function:

```julia
julia> bench_dicttype(RedBlackTrie, 10)
(size = 10, search_hit_ns = 40, search_miss_ns = 26)

julia> bench_dicttype(RedBlackTrie, 100)
(size = 100, search_hit_ns = 55, search_miss_ns = 39)

julia> bench_dicttype(RedBlackTrie, 100_000)
(size = 100000, search_hit_ns = 89, search_miss_ns = 68)

julia> bench_dicttype(RedBlackTrie, 1_000_000)
(size = 1000000, search_hit_ns = 109, search_miss_ns = 86)
```

## `biterate`: iterating over sequences of bits

`@trie` takes, as an optional argument, a `keyfunc` that reinterprets the input
key as a sequence of simpler keys. By default, `keyfunc` is equal to
`codeunits` for `String` keys, in order to correctly handle strings with
variable-width character encodings.

[`PureFun.Contiguous.biterate`](@ref), which takes an integer key and
efficiently[^biterate] reinterprets it as a sequence of smaller integers, is
especially relevant to the current discussion. The resulting sequence can be
thought of as vector indexes, and in keeping with Julia's convention of 1-based
indexing, the iterated elements start at 1. In the following example, we
iterate over the input 8 bits at a time, outputting sequences of integers in
the range $[1, 256]$ (since $2^{8} == 256$)

[^biterate]: `biterate` works by consuming its input a few bits at a time, and
             interprets those bits as an integer (after adding a 1). It is
             implemented in terms of bit-shifting operations and so is very
             fast.

=#

for i in PureFun.Contiguous.biterate(8, 19481210) println(i) end

#=

We can use `biterate` to help us chain together `BitMap`s to store larger
integer keys, we call the resulting structure a bitmapped trie or bitmapped
array trie:

=#

@trie(BitMapTrie,
      edgemap = PureFun.Contiguous.bitmap(64),
      keyfunc = PureFun.Contiguous.biterate(6))

#=

This dictionary type can only store integer keys, so instead of running it
through the usual tests, we just run these ad hoc tests to make sure things are
working:

=#

bmt = BitMapTrie((0 => "wee", 1 => "hello", 2 => "world"))
@assert bmt[2] == "world"
@assert length(bmt) == 3

#=

In the worst case, a lookup in `BitMapTrie` takes 13 memory accesses, one for
each chunk of bits that we use to represent the 64 bit input[^biteratelength].
But due to path compression, if our keys are spread out we'll only ever have to
lookup a couple of the indexes before uniquely identifying a key. For that
reason, when combined with a good hash function, `BitMapTrie` makes an ideal
`approx` dictionary for a hash table:

[^biteratelength]: since 5 doesn't divide evenly into 64, the last index
                   produced by `biterate` will only have 4 bits and sit in the
                   range $[1,16]$. Also we can reduce the worst-case number of
                   memory accesses in this case by using a smaller key, such as
                   a 32-bit or 16-bit integer (`Int32` or `Int16`).


=#

@hashmap(HAMT,
         approx = BitMapTrie,
         exact  = PureFun.Association.List)

test_dicttype(HAMT)

#=

```julia
julia> bench_dicttype(HAMT, 10)
(size = 10, search_hit_ns = 31, search_miss_ns = 14)

julia> bench_dicttype(HAMT, 100)
(size = 100, search_hit_ns = 42, search_miss_ns = 21)

julia> bench_dicttype(HAMT, 100_000)
(size = 100000, search_hit_ns = 58, search_miss_ns = 49)

julia> bench_dicttype(HAMT, 1_000_000)
(size = 1000000, search_hit_ns = 75, search_miss_ns = 49)
```

The HAMT is described as a constant-time container, so why does it look like
search times increase (gradually -- notice that each of the last two steps are
1000x increases in number of elements) with the number of elements?

Our hash function maps all keys to hashes of the same length. As a result, the
worst-case lookup time after having calculated the hash is in fact constant,
defined by the total number of hops, 5 bits at a time, required to consume 64
bits[^caveat].

But as we can see, in practice lookups are much faster than the theoretical
worst-case due to the path compression in the tries. We only end up using as
much of the hash as is necessary to uniquely identify a key. That number will
grow slowly as we keep adding additional elements, and as a result the observed
search times will slowly approach the theoretical worst-case.

[^caveat]: Barring a hash collision, which is extremely unlikely outside of an
           adversarial attack, as we are using the full 64 bits of the hash

## References and further reading

The idea of tries as bootstrapping a finite map over a simple type to a finite
map over aggregate types is introduced in section 10.3.1 in *Purely Functional
Data Structures*. Exercise 10.10 describes collapsing paths of nodes with only
a single child into a single node, such that no node is both invalid and an
only child. However, that exercise suggests achieving this by storing in each
node the longest common prefix of the keys stored below. Trie path compression
in PureFun.jl, on the other hand, follows the section "Compressed trie with
digit number" in [these notes by Sartaj
Sahni](https://www.cise.ufl.edu/~sahni/dsaac/enrich/c16/tries.htm), resulting
in a much more compact (and as a result, performant) trie structure.

The Array Mapped Tree, the inspiration for [`PureFun.Contiguous.bitmap`](@ref),
is described in [Fast and Space Efficient Trie
Searches](https://www.semanticscholar.org/paper/Fast-And-Space-Efficient-Trie-Searches-Bagwell/93a1fe7f226cfbc7cb2bceac39308a66c8aef0b0).

The idea behind [`PureFun.Contiguous.biterate`](@ref), iterating over several
bits of an integer at a time, is presented in [Ideal Hash
Trees](https://www.semanticscholar.org/paper/Ideal-Hash-Trees-Bagwell/4fc240d0d9e690cb9b0bcb2f8a5e5ca918b01410).
That paper introduces the HAMT as it is described here.

[This presentation by @theVtuberCh](https://youtu.be/xz0Vh5BbBic) is a good
introduction to Hash Array Mapped Tries and several related concepts and data
structures.

=#
