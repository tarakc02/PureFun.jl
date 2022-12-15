"""
    PFList{T}

Supertype for purely functional lists with elements of type `T`.

A `PFList` implements `cons` (equivalent to `pushfirst`), `head`, `tail`,
`getindex`, `setindex`, `append` and `reverse`.

See also [`PureFun.Linked.List`](@ref), [`PureFun.RandomAccess.List`](@ref),
and [`PureFun.Catenable.List`](@ref)
"""
abstract type PFList{T} end
#abstract type PFList{T} <: AbstractVector{T} end

"""
    cons(x, xs::PFList)
    pushfirst(xs::PFList, x)
    x ⇀ xs

Return the `PFList` that results from adding `x` to the front of `xs`.
"""
function cons end

"""
    cons(x, xs::PFList)
    pushfirst(xs::PFList, x)
    x ⇀ xs

Return the `PFList` that results from adding `x` to the front of `xs`.
"""
pushfirst(xs::PFList, x) = cons(x, xs)
push(xs::PFList, x) = snoc(xs, x)

"""
    head(xs)
    first(xs)

Return the first element of a `PFList` or `PFQueue`. See also [`tail`](@ref)
"""
function head end

"""
    popfirst(xs)
    tail(xs)

Return the collection `xs` without its first element (without modifying `xs`).
"""
function tail end
Base.tail(xs::PFList) = tail(xs)

"""
    append(xs, ys)
    xs ⧺ ys

Concatenate two `PFLists`.

```@jldoctest
julia> l1 = PureFun.Linked.List(1:3);

julia> l2 = PureFun.Linked.List(4:6);

julia> l1 ⧺ l2
1
2
3
4
5
6

```
"""
function append end

"""
return a reversed version of the input list
"""
Base.reverse(l::PFList) = foldl(pushfirst, l, init=empty(l))
append(l1::PFList, l2::PFList) = foldr(cons, l1, init=l2)

"""
    setindex(l::PFList, newval, ind)

Return a new list with the value at index `ind` set to `newval`

# Examples

```jldoctest
julia> using PureFun, PureFun.RandomAccess

julia> l = RandomAccess.List(1:10)
10-element PureFun.RandomAccess.List{Int64}
1
2
3
4
5
6
7
...

julia> setindex(l, 99, 4)
10-element PureFun.RandomAccess.List{Int64}
1
2
3
99
5
6
7
...

```
"""
function Base.setindex(l::PFList, newval, ind)
    new = empty(l)
    cur = l
    i = ind
    while i > 1 && !isempty(cur)
        i -= 1
        new = cons(head(cur), new)
        cur = tail(cur)
    end
    i > 1 && throw(BoundsError(l, ind))
    return reverse(cons(newval, new)) ⧺ tail(cur)
end

@doc raw"""
    insert(list::PFList, ix, v)

Return a new list with the element `v` inserted at index `ix`.
"""
function PureFun.insert(l::PFList, ix, v)
    new = empty(l)
    cur = l
    i = ix
    while i > 1 && !isempty(cur)
        i -= 1
        new = cons(head(cur), new)
        cur = tail(cur)
    end
    i > 1 && throw(BoundsError(l, ix))
    foldl(pushfirst, v ⇀ new, init = cur)
end

Base.filter(f, l::PFList) = foldr(cons, Iterators.filter(f, l), init=empty(l))
Base.map(f, l::PFList) = mapfoldr(f, cons, l, init=empty(l, infer_return_type(f, l)))
Base.lastindex(l::PFList) = length(l)

struct AccumInit end

function Base.accumulate(f, l::PFList; init=AccumInit())
    y = init isa AccumInit ? head(l) : f(head(l), init)
    cons(y, _accum(f, tail(l), y))
end

function _accum(f, l::PFList, accum)
    isempty(l) && return(empty(l, typeof(accum)))
    y = f(accum, head(l))
    cons(y, _accum(f, tail(l), y))
end

function drop(l::PFList, n)
    while !isempty(l) && n > 0
        l = tail(l)
    end
    return l
end

@doc raw"""

    halfish(xs)

Split `xs` *roughly* in half, and return the two halves as a tuple (front,
back).

# Examples

```jldoctest
julia< using PureFun
julia> l = PureFun.Linked.List(1:100)
100-element PureFun.Linked.NonEmpty{Int64}
1
2
3
4
5
6
7
...

julia> halves = halfish(l)
(1, 2, 3, 4, 5, ..., 51, 52, 53, 54, 55, ...)

julia> length(halves[1]), length(halves[2])
(50, 50)

julia> halves[2]
50-element PureFun.Linked.NonEmpty{Int64}
51
52
53
54
55
56
57
...
```
"""
function halfish(xs::PFList)
    len = length(xs)
    at = cld(len, 2)
    rest = xs
    revtop = empty(xs)
    while at > 0
        revtop = rest[1] ⇀ revtop
        rest = popfirst(rest)
        at -= 1
    end
    return reverse(revtop), rest
end

halve(xs::PFList) = halfish(xs)
amount(xs::PFList) = length(xs)
