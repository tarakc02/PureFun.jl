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
      end
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

