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

struct Weight
    _weight::Int32
end

@inline function Base.getproperty(w::Weight, s::Symbol)
    if s == :weight
        getbits(w._weight, 1, 31)
    elseif s == :oneway
        convert(Bool, getbits(w._weight, 32))
    else
        Base.getfield(w, s)
    end
end


# Edge-based node weights, durations, and distances are stored in a separate file with parallel
# arrays

function read_edge_based_node_weights(osrm)
    ebwn = read_tar_mmap(osrm * ".enw", strict=false)

    # weights
    n_weights = read_count(ebwn, "/extractor/edge_based_node_weights.meta")
    weightsraw = @view get_member(ebwn, "/extractor/edge_based_node_weights")[1:n_weights * sizeof(Weight)]
    weights = reinterpret(reshape, Weight, reshape(weightsraw, sizeof(Weight), :))

    # durations
    n_durations = read_count(ebwn, "/extractor/edge_based_node_durations.meta")
    durationsraw = @view get_member(ebwn, "/extractor/edge_based_node_durations")[1:n_durations * sizeof(Int32)]
    durations = reinterpret(reshape, Int32, reshape(durationsraw, sizeof(Int32), :))

    # durations
    n_distances = read_count(ebwn, "/extractor/edge_based_node_distances.meta")
    distancesraw = @view get_member(ebwn, "/extractor/edge_based_node_distances")[1:n_distances * sizeof(Float32)]
    distances = reinterpret(reshape, Float32, reshape(distancesraw, sizeof(Float32), :))

    return (weights=weights, durations=durations, distances=distances)
end