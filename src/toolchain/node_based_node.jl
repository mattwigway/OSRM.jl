const FIXED_LON_SCALE_FACTOR = 1e6
# TODO this was changed from 33 recently, and eventually will go to 35 as OSM evolves. Any way to autodetect from file?
const BITS_PER_NODE_ID = 34 # 63 in telenav fork, https://github.com/Telenav/open-source-spec/blob/master/osrm/doc/osrm-toolchain-files/map.osrm.nbg_nodes.md

struct Coordinate
    fixed_lon::Int32
    fixed_lat::Int32
end

function Base.getproperty(c::Coordinate, s::Symbol)
    if s == :lon
        c.fixed_lon / 1e6
    elseif s == :lat
        c.fixed_lat / 1e6
    else
        getfield(c, s)
    end
end

function load_node_coordinates(osrm)
    nmmap = read_tar_mmap(osrm * ".nbg_nodes", strict=false)
    n_nodes = read_count(nmmap, "/common/nbn_data/coordinates.meta")
    clistraw = @view get_member(nmmap, "/common/nbn_data/coordinates")[1:(n_nodes * sizeof(Coordinate))]
    return reinterpret(reshape, Coordinate, reshape(clistraw, sizeof(Coordinate), :))
end

bitsizeof(T) = 8 * sizeof(T)

function load_node_ids(osrm)
    nmmap = read_tar_mmap(osrm * ".nbg_nodes", strict=false)
    n_nodes = read_count(nmmap, "/common/nbn_data/osm_node_ids/number_of_elements.meta")
    packed_raw = get_member(nmmap, "/common/nbn_data/osm_node_ids/packed")
    packed_trunc = @view packed_raw[begin:end - length(packed_raw) % sizeof(UInt64)]
    packed_64 = reinterpret(reshape, UInt64, reshape(packed_trunc, sizeof(UInt64), :))
    
    return PackedVector(Int64, packed_64, n_nodes, BITS_PER_NODE_ID)
end

struct PackedVector{T <: Integer} <: AbstractVector{T}
    nelements::Int64
    elements_per_block::Int64
    low_masks::Vector{UInt64}
    high_masks::Vector{UInt64}
    low_offsets::Vector{UInt8}
    high_offsets::Vector{UInt8}
    bitsize::Int64
    data::AbstractVector{UInt64}
end

PackedVector(T, data, nelements, bitsize) = PackedVector{T}(
    convert(Int64, nelements),
    elements_per_block(bitsize),
    create_low_masks(bitsize),
    create_high_masks(bitsize),
    create_low_offsets(bitsize),
    create_high_offsets(bitsize),
    bitsize,
    data)

# how many words in a "block" (i.e. the distance between places where the edges of elements line up with Int64 boundaries)
blocksize(bitsize) = lcm(bitsize, 8 * sizeof(UInt64)) ÷ sizeof(UInt64)

elements_per_block(bitsize) = (blocksize(bitsize) * 8) ÷ bitsize

# Preinitialize masks and offsets as done in OSRM for efficiency

create_low_masks(bitsize) = map(1:elements_per_block(bitsize)) do el
    # how many bits into the file we are
    total_bit_offset = (el - 1) * bitsize

    # How many bits to skip from the lower part
    lower_bit_skip = total_bit_offset % bitsizeof(UInt64)

    # How many bits to grab from the lower part
    lower_bit_grab = min(bitsizeof(UInt64) - lower_bit_skip, bitsize)

    if lower_bit_grab > 0
        bitmask(UInt64, lower_bit_skip + 1, lower_bit_skip + lower_bit_grab)
    else
        zero(UInt64)
    end
end

create_high_masks(bitsize) = map(1:elements_per_block(bitsize)) do el
    # how many bits into the file we are
    total_bit_offset = (el - 1) * bitsize

    # How many bits to skip from the lower part
    lower_bit_skip = total_bit_offset % bitsizeof(UInt64)

    # How many bits to grab from the lower part
    lower_bit_grab = min(bitsizeof(UInt64) - lower_bit_skip, bitsize)

    # How many bits to grab from the upper part
    upper_bit_grab = max(bitsize - lower_bit_grab, 0)

    if upper_bit_grab > 0
        bitmask(UInt64, 1, upper_bit_grab)
    else
        zero(UInt64)
    end
end

create_low_offsets(bitsize) = map(1:elements_per_block(bitsize)) do el
    # how many bits into the file we are
    total_bit_offset = (el - 1) * bitsize

    # How many bits to skip from the lower part
    total_bit_offset % bitsizeof(UInt64)
end

create_high_offsets(bitsize) = map(1:elements_per_block(bitsize)) do el
    # how many bits into the file we are
    total_bit_offset = (el - 1) * bitsize

    # How many bits to skip from the lower part
    lower_bit_skip = total_bit_offset % bitsizeof(UInt64)

    # How many bits to grab from the lower part
    min(bitsizeof(UInt64) - lower_bit_skip, bitsize)
end

function Base.getindex(v::PackedVector{T}, i::Int) where T
    if i ≤ 0 || i > v.nelements
        throw(BoundsError(v, i))
    end

    # how many bits into the file we are
    total_bit_offset = (i - 1) * v.bitsize

    # how many whole UInt64s are we into the file
    node_byte_offset = total_bit_offset ÷ bitsizeof(UInt64) + 1

    lowpart = (v.data[node_byte_offset] & v.low_masks[(i - 1) % v.elements_per_block + 1]) >> v.low_offsets[(i - 1) % v.elements_per_block + 1]
    hipart = (v.data[node_byte_offset + 1] & v.high_masks[(i - 1) % v.elements_per_block + 1]) << v.high_offsets[(i - 1) % v.elements_per_block + 1]
    
    convert(T, lowpart | hipart)
end

Base.size(v::PackedVector) = (v.nelements,)
Base.axes(v::PackedVector) = (1:v.nelements,)
Base.eltype(::PackedVector{T}) where T = T