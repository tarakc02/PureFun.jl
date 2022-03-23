#=

we want to be able to traverse in the following ways:

- just find the node and do something when we get there (findnode), no path
  copying and no need to backtrack. e.g. for `Base.in`

- travel to a node while keeping track of the path, in order to backtrack and
  travel to nearby nodes without restarting from the root. this is path
  copying, but we end up with the path in reverse

- go to a node while copying the path from the root on the way there. e.g. for
  insert/delete operations. this type of traversal is implemented within the
  insert and delete code, because it can require specific reshaping rules on
  the way

=#

# plain traversal {{{
return_true(x) = true
return_false(x) = false
Base.in(key, tree::NE) = traverse(tree, key, return_true, return_false)

function Base.minimum(tree::NE)
    while !isempty(left(tree))
        tree = left(tree)
    end
    elem(tree)
end

function Base.maximum(tree::NE)
    while !isempty(right(tree))
        tree = right(tree)
    end
    elem(tree)
end

traverse(::E, key, found, notfound) = notfound(key)
function traverse(tree::NE, key, found::Function, notfound::Function)
    candidate = empty(tree)
    while !isempty(tree)
        if smaller(key, tree)
            tree = tree.left
        else
            candidate = tree
            tree = tree.right
        end
    end
    isempty(candidate) && return notfound(key)
    smaller(candidate, key) ? notfound(key) : found(candidate)
end

# }}}

# traversal with backtracking {{{

# create a trail to the smallest node from a given root
function mintrail(node::Black{T,O}) where {T,O} 
    mintrail(cons(node, Linked.Empty{ NonEmpty{T,O} }()))
end
function mintrail(path::Linked.NonEmpty)
    l = left(head(path))
    isempty(l) ? path : mintrail(cons(l, path))
end

function maxtrail(node::Black{T,O}) where {T,O} 
    maxtrail(cons(node, Linked.Empty{ NonEmpty{T,O} }()))
end
function maxtrail(path::Linked.NonEmpty)
    r = right(head(path))
    isempty(r) ? path : maxtrail(cons(r, path))
end

function next_inorder(path::Linked.NonEmpty{<:NonEmpty})
    r = right(head(path))
    !isempty(r) && return mintrail(cons(r, path))
    isempty(tail(path)) && return empty(path)
    cur = path
    par = tail(cur)
    while !isempty(par) && head(cur) === right(head(par))
        cur = par
        par = tail(cur)
    end
    par
end

function prv_inorder(path::Linked.NonEmpty{<:NonEmpty})
    l = left(head(path))
    !isempty(l) && return maxtrail(cons(l, path))
    isempty(tail(path)) && return empty(path)
    cur = path
    par = tail(cur)
    while !isempty(par) && head(cur) === left(head(par))
        cur = par
        par = tail(cur)
    end
    par
end

# }}}

Base.iterate(::E) = nothing
function Base.iterate(t::RB)
    min = mintrail(t)
    elem(head(min)), min
end
function Base.iterate(t::RB, state)
    next = next_inorder(state)
    isempty(next) && return nothing
    return elem(head(next)), next
end

