# vim: set ts=4 sts=0 sw=4 si fenc=utf-8 et:
# vim: set fdm=marker fmr={{{,}}} fdl=0 foldcolumn=4:

struct HeightViol{T<:NonRed}
    node::T
end

# if we've reduced the size of a black-rooted tree, but the new root is red,
# we can keep the old size by re-coloring it. else pass along the violation
maybe_viol(tree::E) = HeightViol(tree)
maybe_viol(tree::Red) = turn_black(tree)

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

hvbalance(key, left::Valid, right::Valid) = HeightViol(Black(key, left, right))

function hvbalance(key, left::RedViolR, right::Valid)
    Black(elem(left.right),
          Black(elem(left), left.left, left.right.left),
          Black(key, left.right.right, right))
end

function hvbalance(key, left::Valid, right::RedViolL)
    Black(elem(right.left),
          Black(key, left, right.left.left),
          Black(elem(right), right.left.right, right.right))
end

function fixup_black(key, left::HeightViol, right::Black)
    hvbalance(elem(right), Red(key, turn_black(left), right.left), right.right)
end

function fixup_black(key, left::Black, right::HeightViol)
    hvbalance(elem(left), left.left, Red(key, left.right, turn_black(right)))
end

#function fixup_black(key, left::HeightViol, right::Black)
#    if right.right isa Red
#        return Black(elem(right),
#                     Black(key, turn_black(left), right.left),
#                     turn_black(right.right))
#    elseif right.left isa Red
#        return Black(elem(right.left),
#                     Black(key, turn_black(left), right.left.left),
#                     Black(elem(right), right.left.right, right.right))
#    else
#        return HeightViol(balance(key, turn_black(left), turn_red(right)))
#    end
#end

function fixup_black(key, left::Red, right::HeightViol)
    Black(elem(left),
          left.left,
          balance(elem(left.right),
                  left.right.left,
                  Red(key, left.right.right, turn_black(right))))
end

#function fixup_black(key, left::Black, right::HeightViol)
#    if left.left isa Red
#        return Black(elem(left),
#                     turn_black(left.left),
#                     Black(key, left.right, turn_black(right)))
#    elseif left.right isa Red
#        return Black(elem(left.right),
#                     Black(elem(left), left.left, left.right.left),
#                     Black(key, left.right.right, turn_black(right)))
#    else
#        return HeightViol(balance(key, turn_red(left), turn_black(right)))
#    end
#end

# }}}

# and fixup red {{{
function fixup_red(key, left::NonRed, right::NonRed)
    Red(key, left, right)
end

function fixup_red(key, left::HeightViol, right::Black)
    balance(elem(right), Red(key, turn_black(left), right.left), right.right)
end

function fixup_red(key, left::Black, right::HeightViol)
    balance(elem(left), left.left, Red(key, left.right, turn_black(right)))
end
# }}}

# delete min and max {{{
function dmin(node::Red)
    isempty(left(node)) && return right(node)
    fixup_red(elem(node), dmin(left(node)), right(node))
end

function dmin(node::Black)
    isempty(left(node)) && return maybe_viol(right(node))
    fixup_black(elem(node), dmin(left(node)), right(node))
end

function dmax(node::Red)
    isempty(right(node)) && return left(node)
    fixup_red(elem(node), left(node), dmax(right(node)))
end

function dmax(node::Black)
    isempty(right(node)) && return maybe_viol(left(node))
    fixup_black(elem(node), left(node), dmax(right(node)))
end

function PureFun.delete_min(root::Black)
    res = dmin(root)
    turn_black(res)
end

function PureFun.delete_max(root::Black)
    res = dmax(root)
    turn_black(res)
end
# }}}

# arbitrary deletion {{{

_delete(tree::E, key) = throw(KeyError(key))

function _delete(tree::Black, key)
    if smaller(key, tree)
        fixup_black(elem(tree),
                    _delete(left(tree), key),
                    right(tree))
    elseif smaller(tree, key)
        fixup_black(elem(tree),
                    left(tree),
                    _delete(right(tree), key))
    elseif isempty(right(tree))
        maybe_viol(left(tree))
    else
        nxt, new_rt = popmin(right(tree))
        fixup_black(nxt, left(tree), new_rt)
    end
end

function _delete(tree::Red, key)
    if smaller(key, tree)
        fixup_red(elem(tree),
                  _delete(left(tree), key),
                  right(tree))
    elseif smaller(tree, key)
        fixup_red(elem(tree),
                  left(tree),
                  _delete(right(tree), key))
    elseif isempty(right(tree))
        left(tree)
    else
        nxt, new_rt = popmin(right(tree))
        fixup_red(nxt, left(tree), new_rt)
    end
end

popmin(tree) = minimum(tree), dmin(tree)

PureFun.delete(tree::Black, key) = turn_black(_delete(tree, key))


# }}}
