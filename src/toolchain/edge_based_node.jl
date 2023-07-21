"""
An edge-based node is a node from the edge-based graph, corresponding to an edge in the node-based graph.
All of the IDs are 31-bit ints with a boolean packed into the most-significant-bit of the most-significant-byte.
"""
struct EdgeBasedNode
    packed_geometry_id::UInt32
    packed_component_id::UInt32
    packed_annotation_id::UInt32
end

# custom getproperty to unpack the packed ints
@inline function Base.getproperty(n::EdgeBasedNode, s::Symbol)
    if s == :geometry_id
        getbits(n.packed_geometry_id, 1, 31)
    elseif s == :forward
        convert(Bool, getbits(n.packed_geometry_id, 32))
    elseif s == :component_id
        getbits(n.packed_component_id, 1, 31)
    elseif s == :is_tiny
        convert(Bool, getbits(n.packed_component_id, 32))
    elseif s == :annotation_id
        getbits(n.packed_annotation_id, 1, 31)
    elseif s == :segregated
        convert(Bool, getbits(n.packed_annotation_id, 32))
    else
        getfield(n, s)
    end
end

function load_edge_based_nodes(osrm)
    ebgn = read_tar_mmap(osrm * ".ebg_nodes", strict=false)
    n_ebn = read_count(ebgn, "/common/ebg_node_data/nodes.meta")
    @info "$n_ebn edge-based nodes"

    ebnlistraw = @view get_member(ebgn, "/common/ebg_node_data/nodes")[1:(n_ebn * sizeof(EdgeBasedNode))]
    return reinterpret(reshape, EdgeBasedNode, reshape(ebnlistraw, sizeof(EdgeBasedNode), :))
end