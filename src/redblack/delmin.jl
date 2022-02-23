# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

struct HeightViol{T}
    node::Union{Black{T}, E{T}}
end

wrap(right::E{T}) where {T} = HeightViol{T}(right)
wrap(right::Red{T}) where {T} = turn_black(right)

# helpers {{{
turn_black(t::E{T}) where {T} = t
turn_black(t::HeightViol{T}) where {T} = turn_black(t.node)

turn_red(t::Black{T}) where {T} = Red(t.key, t.left, t.right)
# }}}

# `fixup` dispatches based on presence of height-balance violations (2 versions)

# fixup_black: {{{

# no fixes necessary, copy only
function fixup_black(key, left::RB{T}, right::RB{T}) where {T}
    Black(key, left, right)
end

# special cases:
function fixup_black(key::T, left::HeightViol{T}, right::Red{T}) where {T}
    Black(right.key,
          balance(right.left.key,
                  Red(key, turn_black(left), right.left.left),
                  right.left.right),
          right.right)
end

function fixup_black(key::T, left::HeightViol{T}, right::Black{T}) where {T}
    if is_red(right.right)
        return Black(right.key,
                     Black(key, turn_black(left), right.left),
                     turn_black(right.right))
    elseif is_red(right.left)
        return Black(right.left.key,
                     Black(key, turn_black(left), right.left.left),
                     Black(right.key, right.left.right, right.right))
    else
        return HeightViol{T}(balance(key, turn_black(left), turn_red(right)))
    end
end
# }}}

# and fixup red {{{
function fixup_red(
        key::T,
        left::Union{Black{T}, E{T}},
        right::Union{Black{T}, E{T}}) where {T}
    Red(key, left, right)
end

function fixup_red(key, left::HeightViol{T}, right::Black{T}) where {T}
    balance(right.key, Red(key, turn_black(left), right.left), right.right)
end
# }}}

function dm(node::Red{T}) where {T}
    is_empty(node.left) && return node.right
    fixup_red(node.key, dm(node.left), node.right)
end

function dm(node::Black{T}) where {T}
    is_empty(node.left) && return wrap(node.right)
    fixup_black(node.key, dm(node.left), node.right)
end

function delete_min(root::Black{T}) where {T}
    res = dm(root)
    turn_black(res)
end

