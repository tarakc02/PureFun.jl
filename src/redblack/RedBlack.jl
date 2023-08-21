module RedBlack

using ..PureFun
using ..PureFun.Linked

export up_from, down_from

include("basics.jl")
include("insert.jl")
include("traversal.jl")
include("delete.jl")
include("from-sorted.jl")

# pretty printing {{{
function Base.show(::IO, ::MIME"text/plain", t::E{T}) where {T} 
    println("an empty rb-tree of type $(typeof(t))")
end

function Base.show(::IO, ::MIME"text/plain", t::NonEmpty{T}) where {T} 
    len = length(t)
    n = 3
    it = mintrail(t)
    while !isempty(it) && n > 0
        println(elem(head(it)))
        it = next_inorder(it)
        n -= 1
    end
    if isempty(it) return nothing end
    if (len-3) > 3 println("⋮") end
    rit = maxtrail(t)
    rn = min(len-4, 2)
    while !isempty(rit) && rn > 0
        rit = prv_inorder(rit)
        rn -= 1
    end
    while !isempty(rit) && rn <= 3
        println(elem(head(rit)))
        rit = next_inorder(rit)
        rn += 1
    end
end
# }}}

# PFDict interface {{{
dictkey(p::Pair) = p.first
dictkey(x) = x
dictorder(o) = Base.Order.By(dictkey, o)

@doc raw"""

    RedBlack.RBDict{O,K,V} where O
    RedBlack.RBDict{K,V}(ord=Base.Order.Forward)
    RedBlack.RBDict(iter, o::Ordering=Base.Order.Forward)

Immutable dictionary implemented using a red-black tree (balanced binary search
tree). All major operations are $\mathcal{O}(\log{}n)$. Note the ordering
parameter, the RBDict iterates in sorted order according to the ordering `O`.
In addition to the main `PFDict` methods, `RBDict` implements `delete`,
`popmin`, and `popmax`.

# Examples

```jldoctest
julia> using PureFun, PureFun.RedBlack

julia> f = RedBlack.RBDict(("zyz" => 1, "abc" => 2, "ghi" => 3))
PureFun.RedBlack.RBDict{Base.Order.ForwardOrdering, String, Int64} with 3 entries:
  "abc" => 2
  "ghi" => 3
  "zyz" => 1

julia> b = RedBlack.RBDict(("zyz" => 1, "abc" => 2, "ghi" => 3), Base.Order.Reverse)
PureFun.RedBlack.RBDict{Base.Order.ReverseOrdering{Base.Order.ForwardOrdering}, String, Int64} with 3 entries:
  "zyz" => 1
  "ghi" => 3
  "abc" => 2

julia> popmin(f)
PureFun.RedBlack.RBDict{Base.Order.ForwardOrdering, String, Int64} with 2 entries:
  "ghi" => 3
  "zyz" => 1

julia> popmax(f)
PureFun.RedBlack.RBDict{Base.Order.ForwardOrdering, String, Int64} with 2 entries:
  "abc" => 2
  "ghi" => 3

julia> popmin(b)
PureFun.RedBlack.RBDict{Base.Order.ReverseOrdering{Base.Order.ForwardOrdering}, String, Int64} with 2 entries:
  "ghi" => 3
  "abc" => 2

julia> popmax(b)
PureFun.RedBlack.RBDict{Base.Order.ReverseOrdering{Base.Order.ForwardOrdering}, String, Int64} with 2 entries:
  "zyz" => 1
  "ghi" => 3

julia> delete(b, "ghi")
PureFun.RedBlack.RBDict{Base.Order.ReverseOrdering{Base.Order.ForwardOrdering}, String, Int64} with 2 entries:
  "zyz" => 1
  "abc" => 2

# forward-ordered by default, so:
julia> d = RedBlack.RBDict{Base.Order.ForwardOrdering}{String,Int}();
julia> d === RedBlack.RBDict{String,Int}()
true
```
"""
struct RBDict{O,K,V} <: PureFun.PFDict{K,V} where O
    t::NonRed{Pair{K,V}, Base.Order.By{typeof(PureFun.RedBlack.dictkey), O}}
end

function RBDict{K,V}(ord=Base.Order.Forward) where {K,V}
    o = dictorder(ord)
    t = E{ Pair{K,V} }(o)
    RBDict{typeof(ord),K,V}(t)
end

function RBDict{O,K,V}() where {O,K,V}
    o = dictorder(O())
    t = E{ Pair{K,V} }(o)
    RBDict{O,K,V}(t)
end

RBDict(t::NonRed{ Pair{K,V},O }) where {K,V,O} = RBDict{O,K,V}(t)

function RBDict(iter, o::Ordering=Forward)
    t = RB(iter, dictorder(o))
    RBDict(t)
end

Base.isempty(d::RBDict) = isempty(d.t)

function Base.empty(d::RBDict{O,K,V}) where {O,K,V}
    t = empty(d.t)
    RBDict{O,K,V}(t)
end

PureFun.push(d::RBDict, pair) = RBDict(insert(d.t, pair))
Base.setindex(d::RBDict, v, k) = RBDict(insert(d.t, Pair(k,v)))
val(p) = elem(p).second
Base.get(d::RBDict, k, default) = traverse(d.t, k, val, x -> default)
Base.get(f::Function, d::RBDict, k) = traverse(d.t, k, val, x -> f())

# }}}

# PFSet interface {{{
@doc raw"""

    RBSet{O,T} where O
    RBSet{O,T}(ord=Base.Order.Forward)
    RBSet(iter, o=Base.Order.Forward)

An immutable ordered set. All major operations are $\mathcal{O}(\log{}n)$. Note
the ordering parameter, the RBDict iterates in sorted order according to the
ordering `O`. In addition to the main `PFDict` methods, `RBDict` implements
`delete`, `popmin`, and `popmax`.

# Examples

```jldoctest
julia> using PureFun, PureFun.RedBlack

julia> s1 = RedBlack.RBSet(1:10)
1
2
3
⋮
8
9
10


julia> s2 = RedBlack.RBSet(1:10, Base.Order.Reverse)
10
9
8
⋮
3
2
1


julia> 1 ∈ s1, 1 ∈ s2
(true, true)

julia> 17 ∈ s1, 17 ∈ s2
(false, false)

julia> 1 ∈ popmin(s1)
false

julia> 17 ∈ push(s2, 17)
true
```
"""
struct RBSet{O,T} <: PureFun.PFSet{T} where O
    t::NonRed{T,O}
end

function RBSet{T}(ord=Base.Order.Forward) where {T}
    t = E{T}(ord)
    RBSet{typeof(ord),T}(t)
end

function RBSet(iter, o::Ordering=Forward)
    t = RB(iter, o)
    RBSet(t)
end

Base.isempty(s::RBSet) = isempty(s.t)

function Base.empty(s::RBSet{O,T}) where {O,T}
    t = empty(s.t)
    RBSet{O,T}(t)
end

PureFun.push(s::RBSet, x) = RBSet(insert(s.t, x))
Base.in(x, s::RBSet) = traverse(s.t, x, return_true, return_false)

function Base.show(i::IO, m::MIME"text/plain", s::RBSet)
    show(i,m,s.t)
end

# }}}

DS = Union{RBDict, RBSet}

Base.iterate(d::DS) = iterate(d.t)
Base.iterate(d::DS, state) = iterate(d.t, state)
Base.length(d::DS) = length(d.t)

Iterators.reverse(d::DS) = Iterators.reverse(d.t)

PureFun.delete(d::DS, key) = typeof(d)(delete(d.t, key))
PureFun.popmin(d::DS) = typeof(d)(popmin(d.t))
PureFun.popmax(d::DS) = typeof(d)(popmax(d.t))

"""
    up_from(d::Union{RedBlack.RBDict,RedBlack.RBSet}, key)
    down_from(d::Union{RedBlack.RBDict,RedBlack.RBSet}, key)

iterate elements (k=>v pairs when the collection is a dictionary) either up
from the largest element (key) that is less than or equal to the qeury key, or
down from the smallest element (key) that is greater than or equal to the query
key.

# Examples:

```jldoctest
julia> d = RedBlack.RBDict(c => Int(c) for c in 'a':'z')
PureFun.RedBlack.RBDict{Base.Order.ForwardOrdering, Char, Int64} with 26 entries:
  'a' => 97
  'b' => 98
  'c' => 99
  'd' => 100
  'e' => 101
  'f' => 102
  'g' => 103
  'h' => 104
  'i' => 105
  'j' => 106
  ⋮   => ⋮

julia> foreach(println, up_from(d, 'w'))
'w' => 119
'x' => 120
'y' => 121
'z' => 122

julia> foreach(println, down_from(d, 'e'))
'e' => 101
'd' => 100
'c' => 99
'b' => 98
'a' => 97

julia> s = RedBlack.RBSet(1:10)
1
2
3
⋮
8
9
10


julia> foreach(println, down_from(s, 7.5))
7
6
5
4
3
2
1

julia> foreach(println, up_from(s, 7.5))
8
9
10
```
"""
up_from, down_from

up_from(d::DS, key) = up_from(d.t, key)
down_from(d::DS, key) = down_from(d.t, key)

end
