const FIXED_LON_SCALE_FACTOR = 1e6

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

# TODO: node IDs (non-trivial packed format not aligned to bytes)