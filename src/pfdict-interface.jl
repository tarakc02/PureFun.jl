"""

Abstract supertype for immutable dictionaries.

"""
abstract type PFDict{K, V} <: AbstractDict{K, V} end

"""
    update_at(f::Function, d::PFDict, key, default)

return a new dictionary that is otherwise the same as `d`, but sets the value
associated with key `key` by appying function `f` to the current value
"""
function update_at(f::Function, d::PFDict, key, default)
    cur = get(d, key, default)
    setindex(d, f(cur), key)
end
