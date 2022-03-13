# # A purely functional red-black tree
#
# Based on the book *Purely Functional Data Structures*
import Base.Order.Ordering, Base.Order.ForwardOrdering, Base.Order.Forward

abstract type RB{T, O <: Ordering} end

# A tree is either an empty tree:
struct E{T, O <: Ordering} <: RB{T, O}
    order::O
end

# Or it is a node containing a data element along with left and right children:
# storing the `length` will allow fast calculation of quantiles, etc The `C`
# type parameter will hold the node's color, and/or other information required
# to maintain global balance
struct NE{T, C, O <: Ordering} <: RB{T, O} where {C}
    elem::T
    left::Union{E{T, O}, NE{T, :red, O}, NE{T, :black, O}}
    right::Union{E{T, O}, NE{T, :red, O}, NE{T, :black, O}}
    length::Int64
    order::O
end

# By default we use `Base.Order.ForwardOrdering` as the ordering
E{T}(order::Ordering=Forward) where {T} = E{T, typeof(order)}(order)

# In order to [avoid using abstract types in the type
# parameters](https://docs.julialang.org/en/v1/manual/performance-tips/#man-performance-abstract-container),
# hence the awkward union-type rather than just giving `RB{T}` for the type of
# `left` and `right`

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

# we'll use this helper to compare query keys to data
function smaller(tree::RB{T, O}, key::T) where {O <: Ordering, T}
    Base.Order.lt(order(tree), tree.elem, key)
end

function smaller(key::T, tree::RB{T, O}) where {O <: Ordering, T}
    Base.Order.lt(order(tree), key, tree.elem)
end

# Specialize the constructors, now for example there is no way to construct a
# `Red` tree with a `Red` child, helping to maintain that invariant:
function Red(elem::T, left::NonRed{T, O}, right::NonRed{T, O}) where {T, O <: Ordering}
    NE{:red}(elem, left, right)
end

function Black(elem::T, left::Valid{T, O}, right::Valid{T, O}) where {T, O <: Ordering}
    NE{:black}(elem, left, right)
end

# ## Helpers
is_empty(::E) = true
is_empty(::NE) = false

is_red(node) = false
is_red(node::Red) = true

is_black(node) = false
is_black(node::Black) = true

Base.length(::E) = 0
Base.length(t::NE) = t.length

#order(t::RB{T, O}) where { <: Ordering} = O()
order(t::RB) = t.order

function Base.show(::IO, ::MIME"text/plain", t::RB{T}) where {T} 
    len = length(t)
    print("red-black tree with $len element(s)")
end
