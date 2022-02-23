# # Insertion
# 
# ## Some setup
# during insertion, temporarily allow a single red-red violation
RedViolL{T, O} = NE{T, :RVL, O} where {T, O <: Ordering}
RedViolR{T, O} = NE{T, :RVR, O} where {T, O <: Ordering}

RedViol{T, O} = Union{RedViolL{T, O}, RedViolR{T, O}} where {T, O <: Ordering}

RedViolL(key, left, right) = NE{:RVL}(key, left, right)
RedViolR(key, left, right) = NE{:RVR}(key, left, right)

function Red(key, left::Red, right::NonRed)
    RedViolL(key, left, right)
end

function Red(key, left::NonRed, right::Red)
    RedViolR(key, left, right)
end

# convenience function -- returns a copy of a tree, but root painted black.
# When the orinal is the head of a red-red violation, this fixes the issue,
# returning a valid red-black tree that has black-height of one more than the
# original
function turn_black(t::Red)
    Black(t.elem, t.left, t.right)
end
function turn_black(t::RedViol)
    Black(t.elem, t.left, t.right)
end
turn_black(t::Black) = t

# ## The main method
function insert(tree::RB, key)
    res = ins(tree, key)
    turn_black(res)
end

# ## The recursion
#
# recursion dispatches on color of node
ins(::E{T}, key::T) where {T} = Red(key, E{T}(), E{T}())
function ins(t::Red, key)
    smaller(key, t) && return Red(t.elem, ins(t.left, key), t.right)
    smaller(t, key) && return Red(t.elem, t.left, ins(t.right, key))
    return t
end
function ins(t::Black, key)
    smaller(key, t) && return balance(t.elem, ins(t.left, key), t.right)
    smaller(t, key) && return balance(t.elem, t.left, ins(t.right, key))
    return t
end

# ## Balance
#
# `ins` might create a red-red violation. Here we balance red-red violations by
# case

balance(key, left, right) = Black(key, left, right)

function balance(key, left::RedViolL, right::RB)
    x = turn_black(left.left)
    z = Black(key, left.right, right)
    Red(left.elem, x, z)
end

function balance(key, left::RedViolR, right::RB)
    x = Black(left.elem, left.left, left.right.left)
    z = Black(key, left.right.right, right)
    Red(left.right.elem, x, z)
end

function balance(key, left::RB, right::RedViolL)
    x = Black(key, left, right.left.left)
    z = Black(right.elem, right.left.right, right.right)
    Red(right.left.elem, x, z)
end

function balance(key, left::RB, right::RedViolR)
    x = Black(key, left, right.left)
    z = turn_black(right.right)
    Red(right.elem, x, z)
end

# done.
