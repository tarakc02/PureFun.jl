function RB(iter, o::Ordering=Forward)
    elems = sort(unique(collect(iter)), order=o)
    ptree_from_sorted(elems, o)
end


function RBslow(iter, o::Ordering=Forward)
    type = typeof(first(iter))
    reduce(insert, iter, init = E{type}(o))
end

#=
assuming `order` was used to sort `elems`, here i don't do any comparisons,
but i pass the ordering object around in order to be able to construct the
right types
=#
tree_from_sorted(elems, o=Forward) = tree_from_sorted(elems, 1, length(elems), o)
ptree_from_sorted(elems, o=Forward) = ptree_from_sorted(elems, 1, length(elems), o)

function ptree_from_sorted(elems, from, to, o)
    len = to - from + 1
    len < 100 && return tree_from_sorted(elems, from, to, o)
    if iseven(len)
        holdout = elems[from]
        t = ptree_from_sorted(elems, from+1, to, o)
        return insert(t, holdout)
    end
    pivot = div(from+to,2)
    l = Threads.@spawn ptree_from_sorted(elems, from, pivot-1, o)
    r = ptree_from_sorted(elems, pivot+1, to, o)
    Black(elems[pivot], fetch(l), fetch(r))
end

function tree_from_sorted(elems, from, to, o)
    len = to - from + 1
    # basecase where black height is 0
    len < 2 && return little_tree(elems, from, to, o)
    if iseven(len)
        holdout = elems[from]
        t = tree_from_sorted(elems, from+1, to, o)
        return insert(t, holdout)
    end
    pivot = div(from+to,2)
    llen = pivot-1 - from
    rlen = to - (pivot)
    Black(elems[pivot],
          tree_from_sorted(elems, from, pivot-1, o),
          tree_from_sorted(elems, pivot+1, to, o))
end

function little_tree(elems, from, to, o)
    sz = to - from + 1
    e = E{eltype(elems)}(o)
    sz == 0 ? e : Red(elems[from], e, e)
end
