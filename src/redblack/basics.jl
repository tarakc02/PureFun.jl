# # A purely functional red-black tree
#
# Based on the book *Purely Functional Data Structures*
import Base.Order.Ordering, Base.Order.ForwardOrdering, Base.Order.Forward

abstract type RB{T, O <: Ordering} end

# A tree is either an empty tree:
struct E{T, O <: Ordering} <: RB{T, O}
    order::O
end

#=
Or it is a node containing a data element along with left and right children:
The `C` type parameter will hold the node's color, and/or other information
required to maintain global balance In order to [avoid using abstract types in
the type
parameters](https://docs.julialang.org/en/v1/manual/performance-tips/#man-performance-abstract-container),
hence the awkward union-type rather than just giving `RB{T}` for the type of
`left` and `right`
=#
struct NE{T,C,O<:Ordering} <: RB{T,O} where C
    elem::T
    left::Union{E{T,O}, NE{T,:red,O}, NE{T,:black,O}}
    right::Union{E{T, O}, NE{T, :red, O}, NE{T, :black, O}}
    length::Int
    order::O
end

# By default we use `Base.Order.ForwardOrdering` as the ordering
E{T}(order::Ordering=Forward) where {T} = E{T, typeof(order)}(order)
RB{T}() where T = E{T}()
RB{T,O}() where {T,O} = E{T,O}()

# A basic constructor for nonempties. We can infer all but the `C` type
# parameter based on the function arguments. I expect all subtypes of
# `Ordering` to be singleton types, so we can pick up `order` from `left` or
# `right` and it would be the same
function NE{C}(elem::T, left::RB{T, O}, right::RB{T, O}) where {T, C, O <: Ordering}
    len = 1 + length(left) + length(right)
    NE{T, C, O}(elem, left, right, len, order(left))
end

# We won't use `NE` directly, instead we'll use these types for now. When we
# get to insertion and deletion, we'll introduce new `NE` types by introducing
# type-parameters for `C` other than `:red` or `:black`
Black{T, O} = NE{T, :black, O} where {T, O <: Ordering}
Red{T, O} = NE{T, :red, O} where {T, O <: Ordering}
NonRed{T, O} = Union{E{T, O}, Black{T, O}} where {T, O <: Ordering}
Valid{T, O} = Union{E{T, O}, Red{T, O}, Black{T, O}} where {T, O <: Ordering}
NonEmpty{T,O} = Union{Black{T,O}, Red{T,O}}

# we'll use this helper to compare query keys to data
function smaller(tree::RB, key::T) where T
    Base.Order.lt(order(tree), elem(tree), key)
end

function smaller(key::T, tree::RB) where T
    Base.Order.lt(order(tree), key, elem(tree))
end

# Specialize the constructors, now for example there is no way to construct a
# `Red` tree with a `Red` child, helping to maintain that invariant:
function Red(elem, left::NonRed, right::NonRed)
    NE{:red}(elem, left, right)
end

function Black(elem, left::Valid, right::Valid)
    NE{:black}(elem, left, right)
end

# ## Helpers
Base.isempty(::E) = true
Base.isempty(::NE) = false
Base.empty(t::E) = t
Base.empty(t::NE{T,C,O}) where {T,C,O} = E{T}(order(t))

is_red(node) = false
is_red(node::Red) = true

is_black(node) = false
is_black(node::Black) = true

Base.length(::E) = 0
Base.length(t::NE) = t.length

order(t::RB) = t.order
left(t::NE) = t.left
right(t::NE) = t.right
elem(t::NE) = t.elem
Base.eltype(t::RB{T,O}) where {T,O} = T
Base.IteratorSize(::RB) = Base.HasLength()
