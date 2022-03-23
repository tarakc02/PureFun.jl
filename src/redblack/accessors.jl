# # Tree accessors
#
# These are methods for retrieving specific tree nodes

# We can always find the mininmum and maximum nodes without doing a single
# comparison
function Base.minimum(tree::NE)
    isempty(tree.left) && return tree
    return minimum(tree.left)
end

function Base.maximum(tree::NE)
    isempty(tree.right) && return tree
    return maximum(tree.right)
end

findnode(::E, key, found, notfound) = notfound(key)
function findnode(tree::NE, key, found::Function, notfound::Function)
    candidate = tree
    while !isempty(tree)
        if smaller(key, tree)
            tree = tree.left
        else
            candidate = tree
            tree = tree.right
        end
    end
    smaller(candidate, key) ? notfound(key) : found(candidate)
end

#function findnode(::E, key, candidate, found, notfound)
#    smaller(candidate, key) ? notfound(key) : found(candidate)
#end
#
#function findnode(tree::NE, key, found::Function, notfound::Function)
#    smaller(key, tree) && findnode(tree.left, key, found, notfound)
#    findnode(tree.right, key, tree, found, notfound)
#end
#
#function findnode(tree::NE, key, candidate::NE, found, notfound)
#    smaller(key, tree) && findnode(tree.left, key, candidate, found, notfound)
#    findnode(tree.right, key, tree, found, notfound)
#end

const return_true(x) = true
const return_false(x) = false
contains2(tree::NE, key) = findnode(tree, key, return_true, return_false)


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
