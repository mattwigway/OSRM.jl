# The OSRM geometry file is trickier than many others because the geometry is not a fixed length.
# Documentation is here: https://github.com/Telenav/open-source-spec/blob/master/osrm/doc/osrm-toolchain-files/map.osrm.geometry.md#commonsegment_data
# The critical thing that's missing from this is how to know where the end of a geometry is; it's just the start of the next geometry.

# wrap the index and the nodes into a single interface
struct GeometryVector <: AbstractVector{AbstractVector{UInt32}}
    _index::AbstractVector{UInt32}
    _nodes::AbstractVector{UInt32}
end

function Base.getindex(g::GeometryVector, i::Int)
    start = g._index[i + 1] # convert from zero based
    endof = i + 1 == length(g._index) ? length(g._nodes) - 1 : g._index[i + 2] - 1
    return @view g._nodes[start + 1:endof + 1]
end

Base.size(g::GeometryVector) = size(g._index)
Base.axes(g::GeometryVector) = (0:(length(g._index) - 1),)

function load_geometry(osrm)
    geom = read_tar_mmap(osrm * ".geometry", strict=false)
    n_geom = read_count(geom, "/common/segment_data/index.meta")
    
    idx_raw = @view get_member(geom, "/common/segment_data/index")[begin:n_geom * sizeof(UInt32)]
    idx = reinterpret(reshape, UInt32, reshape(idx_raw, sizeof(UInt32), :))
    
    n_nodes = read_count(geom, "/common/segment_data/nodes.meta")
    nodes_raw = @view get_member(geom, "/common/segment_data/nodes")[begin:n_nodes * sizeof(UInt32)]
    nodes = reinterpret(reshape, UInt32, reshape(nodes_raw, sizeof(UInt32), :))

    GeometryVector(idx, nodes)
end