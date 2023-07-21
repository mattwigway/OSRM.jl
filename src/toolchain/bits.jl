# helper functions for bitwise operations
"Create a bitmask with all bits from fr to to (inclusive, one-based) set"
bitmask(T, fr, to=fr) = mapfoldl(x -> one(T) << (x - 1), |, fr:to)

"Get the bits from from to to of v (one-based)"
getbits(v, fr, to=fr) = (v & bitmask(typeof(v), fr, to)) >>> (fr - 1)

read_count(tar, member, T=UInt64) = ltoh(reinterpret(reshape, T, get_member(tar, member)[1:sizeof(T)])[1]) # TODO: will fail on big endian?

struct StaticBitArray{T}
    _values::T
end

Base.getindex(s::StaticBitArray{T}, index::Int) where T = index > 0 && index ≤ sizeof(T) * 8 ? convert(Bool, getbits(s._values, index)) : throw(BoundsError(s, index))
Base.length(::StaticBitArray{T}) where T = sizeof(T)
Base.eachindex(::StaticBitArray{T}) where T = 1:sizeof(T)