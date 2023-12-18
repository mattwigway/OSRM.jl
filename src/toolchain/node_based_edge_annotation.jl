struct NodeBasedEdgeAnnotation
    name_id::UInt32
    lane_description_id::UInt16
    class_data::StaticBitArray{UInt8}
    _travelmode_left_hand_driving::UInt8 # 4 bits / 1 bit
end

@inline function Base.getproperty(a::NodeBasedEdgeAnnotation, s::Symbol)
    if s == :travel_mode
        getbits(a._travelmode_left_hand_driving, 1, 4)
    elseif s == :is_left_hand_driving
        convert(Bool, getbits(a._travelmode_left_hand_driving, 5))
    else
        getfield(a, s)
    end
end

function load_edge_based_node_annotations(osrm)
    # TODO duplicate mmap of same tar file from edge_based_node
    ebgn = read_tar_mmap(osrm * ".ebg_nodes", strict=false)
    n_ebn = read_count(ebgn, "/common/ebg_node_data/annotations.meta")
    @info "$n_ebn edge-based node annotations"

    ebnlistraw = @view get_member(ebgn, "/common/ebg_node_data/annotations")[1:(n_ebn * sizeof(NodeBasedEdgeAnnotation))]
    return reinterpret(reshape, NodeBasedEdgeAnnotation, reshape(ebnlistraw, sizeof(NodeBasedEdgeAnnotation), :))
end
