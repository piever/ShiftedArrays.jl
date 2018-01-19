"""
    ShiftedArray(parent::AbstractArray, shifts)

Custom `AbstractArray` object to store an `AbstractArray` `parent` shifted by `shifts` steps (where `shifts` is
a `Tuple` with one `shift` value per dimension of `parent`).
For `s::ShiftedArray`, `s.v[i...] == v[map(+, i, s.shifts)...]` if `map(+, i, s.shifts)` is a valid index for `v`,
and `s.v[i, ...] == missing` otherwise. Use `copy` to collect the values of a `ShiftedArray`
into a normal `Array`.

# Examples

```jldoctest shiftedarray
julia> v = [1, 3, 5, 4];

julia> s = ShiftedArray(v, (1,))
4-element ShiftedArrays.ShiftedArray{Int64,1,Array{Int64,1}}:
 3
 5
 4
  missing

julia> copy(s)
4-element Array{Union{Int64, Missings.Missing},1}:
 3
 5
 4
  missing
```
"""
struct ShiftedArray{T, N, S<:AbstractArray} <: AbstractArray{Union{T, Missing}, N}
    parent::S
    shifts::NTuple{N, Int64}
end

ShiftedArray(v::AbstractArray{T, N}, n = Tuple(0 for i in 1:N)) where {T, N} = ShiftedArray{T, N, typeof(v)}(v, n)

function ShiftedArray(v::AbstractArray{T, N}, n::Int; dim = 1) where {T, N}
    tup = Tuple(i == dim ? n : 0 for i in 1:N)
    ShiftedArray(v, tup)
end

const ShiftedVector{T, S<:AbstractArray} = ShiftedArray{T, 1, S}

ShiftedVector(v::AbstractVector{T}, n = (0,)) where {T} = ShiftedArray(v, n)

Base.size(s::ShiftedArray) = Base.size(parent(s))

function Base.getindex(s::ShiftedArray{T, N, S}, x::Vararg{Int, N}) where {T, N, S<:AbstractArray}
    i = map(+, x, shifts(s))
    v = parent(s)
    if checkbounds(Bool, v, i...)
        @inbounds ret = v[i...]
    else
        ret = missing
    end
    ret
end

Base.parent(s::ShiftedArray) = s.parent

"""
    shifts(s::ShiftedArray)

Returns amount by which `s` is shifted compared to `parent(s)`.
"""
shifts(s::ShiftedArray) = s.shifts