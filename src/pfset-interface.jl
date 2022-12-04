abstract type PFSet{T} <: AbstractSet{T} end

Base.eltype(::Type{<:PFSet{T}}) where T = T
Base.union(s::PFSet, iter) = reduce(push, iter, init = s)
Base.union(s::PFSet, sets...) = reduce(union, sets, init=s)

function Base.intersect(s::PFSet, iter)
    out = empty(s)
    for i in iter
        if i ∈ s out = push(out, i) end
    end
    return out
end
Base.intersect(s::PFSet, sets...) = reduce(sets, intersect, init=s)

abstract type SetFromDict{T} <: PureFun.PFSet{T} end

@doc raw"""
    @dict2set Name DictType

Given a dictionary implementation, without any extra overhead we can implement
a set by mapping every key to `nothing` and defining the set methods
appropriately. That's what `@dict2set` does.

# Examples

```jldoctest
julia> PureFun.Tries.@trie MyDictionary PureFun.Association.List

julia> PureFun.@dict2set MySet MyDictionary

julia> s = MySet([1,2,2,3,4])
4-element MySet{Int64}
4
3
2
1


julia> push(s, 99)
5-element MySet{Int64}
99
4
3
2
1


julia> 3 ∈ s
true

julia> intersect(s, [1,2,3])
3-element MySet{Int64}
3
2
1
```

"""
macro dict2set(Name, DictType)
    :(
      struct $Name{T} <: SetFromDict{T}
          d::$(esc(DictType)){T,Nothing}
          $Name{T}() where T = new{T}( $(esc(DictType)){T,Nothing}() )
          $Name{T}(d) where T = new{T}(d)
          function $Name(iter)
              init = $Name{Base.@default_eltype(iter)}()
              reduce(push, iter, init = init)
          end
      end;
    Base.empty(s::SetFromDict) = $(esc(Name)){eltype(s)}();
    Base.empty(s::SetFromDict, ::Type{U}) where U = $(esc(Name)){U}()
   )
end

PureFun.push(s::SetFromDict, x) = typeof(s)(setindex(s.d, nothing, x))
Base.in(x, s::SetFromDict) = haskey(s.d, x)

function Base.iterate(s::SetFromDict)
    it = iterate(s.d)
    it === nothing && return nothing
    it[1].first, it[2]
end
function Base.iterate(s::SetFromDict, state)
    it = iterate(s.d, state)
    it === nothing && return nothing
    it[1].first, it[2]
end
Base.length(s::SetFromDict) = length(s.d)

