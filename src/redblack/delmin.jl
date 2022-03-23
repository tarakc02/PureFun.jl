# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

struct HeightViol{T}
    node::Union{Black{T}, E{T}}
end

HeightViol(node::E{T}) where T = HeightViol{T}(node)
HeightViol(node::Black{T}) where T = HeightViol{T}(node)

wrap(right::E{T}) where {T} = HeightViol{T}(right)
wrap(right::Red) = turn_black(right)

# helpers {{{
turn_black(t::E) = t
turn_black(t::HeightViol) = turn_black(t.node)

turn_red(t::Black) = Red(elem(t), left(t), right(t))
# }}}

# `fixup` dispatches based on presence of height-balance violations (2 versions)

# fixup_black: {{{

# no fixes necessary, copy only
function fixup_black(key, left::RB, right::RB)
    Black(key, left, right)
end

# special cases:
function fixup_black(key, left::HeightViol, right::Red)
    Black(elem(right),
          balance(elem(right.left),
                  Red(key, turn_black(left), right.left.left),
                  right.left.right),
          right.right)
end

function fixup_black(key, left::HeightViol, right::Black)
    if is_red(right.right)
        return Black(elem(right),
                     Black(key, turn_black(left), right.left),
                     turn_black(right.right))
    elseif is_red(right.left)
        return Black(elem(right.left),
                     Black(key, turn_black(left), right.left.left),
                     Black(elem(right), right.left.right, right.right))
    else
        return HeightViol(balance(key, turn_black(left), turn_red(right)))
    end
end
# }}}

# and fixup red {{{
function fixup_red(key, left::NonRed, right::NonRed)
    Red(key, left, right)
end

function fixup_red(key, left::HeightViol, right::Black)
    balance(elem(right), Red(key, turn_black(left), right.left), right.right)
end
# }}}

function dm(node::Red)
    isempty(left(node)) && return right(node)
    fixup_red(elem(node), dm(left(node)), right(node))
end

function dm(node::Black)
    isempty(left(node)) && return wrap(right(node))
    fixup_black(elem(node), dm(left(node)), right(node))
end

function PureFun.delete_min(root::Black)
    res = dm(root)
    turn_black(res)
end

