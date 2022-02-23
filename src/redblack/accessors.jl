# # Tree accessors
#
# These are methods for retrieving specific tree nodes
import Base.maximum, Base.minimum, Base.contains

# We can always find the mininmum and maximum nodes without doing a single
# comparison
function minimum(tree::NE)
    is_empty(tree.left) && return tree
    return minimum(tree.left)
end

function maximum(tree::NE)
    is_empty(tree.right) && return tree
    return maximum(tree.right)
end

# see exercise 2.3, instead of doing multiple comparisons at each step, we
# maintain a `candidate` node, the largest node we've seen that is not less
# than `key`
contains(::E, x) = false

function contains(tree::NE, key)
    smaller(key, tree) && return contains(tree.left, key)
    contains(tree.right, key, tree)
end
function contains(tree::NE, key, candidate::NE)
    smaller(key, tree) && return contains(tree.left, key, candidate)
    contains(tree.right, key, tree)
end

# finally, when we've made it to the leaf-node, we check if the candidate (the
# only node that might be a match) is in fact the matching key. Here instead of
# checking for equality, I check `!smaller(candidate, key)` (recall that
# `!smaller(key, candidate)` by construction. this feels a little roundabout,
# but allows me to use only the `smaller` primitive in the code

contains(::E, key, candidate) = !smaller(candidate, key)

#retrieve(::E, key, sucess::Function, failure::Function) = failure()
#
#function retrieve(tree::NE, key, success::Function, failure::Function)
#    smaller(key, tree) && return retrieve(tree.left, key, success, failure)
#    retrieve(tree.right, key, tree, success, failure)
#end
#
#function retrieve(tree::NE, key, candidate::NE, success::Function, failure::Function)
#    smaller(key, tree) && return retrieve(tree.left, key, candidate, success, failure)
#    retrieve(tree.right, key, tree, success, failure)
#end
#
#function retrieve(::E, key, candidate, success::Function, failure::Function)
#    !smaller(candidate, key) && return success(candidate)
#    return failure()
#    #isequal(key, candidate) && return candidate
#    #throw(KeyError(key))
#end
#
#return_true(x) = true
#return_false() = false
#
#function contains(tree, elem)::Bool
#    retrieve(tree, elem, return_true, return_false)
#end
#
#function contains2(tree::NE, key)
#    candidate = tree
#    cur = tree
#    while !is_empty(cur)
#        if smaller(key, cur)
#            cur = cur.left
#        else
#            candidate = cur
#            cur = cur.right
#        end
#    end
#    isequal(candidate.elem, key)
#end
