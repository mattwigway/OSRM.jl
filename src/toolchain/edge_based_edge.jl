struct EdgeBasedEdge
    source_edge_based_node::UInt32
    target_edge_based_node::UInt32
    turn_id::UInt32
    weight::UInt32
    distance::Float32
    _duration_and_direction::UInt32
end

# unpack bit fields
@inline function Base.getproperty(e::EdgeBasedEdge, p::Symbol)
    if p == :duration
        reinterpret(Int32, getbits(ltoh(e._duration_and_direction), 1, 30))
    elseif p == :forward
        convert(Bool, getbits(ltoh(e._duration_and_direction), 31))
    elseif p == :backward
        convert(Bool, getbits(ltoh(e._duration_and_direction), 32))
    else
        getfield(e, p)
    end
end

function load_edge_based_edges(osrm)
    ebg = read_tar_mmap(osrm * ".ebg", strict=false)
    n_ebe = read_count(ebg, "/common/edge_based_edge_list.meta")
    @info "$n_ebe edges"

    ebelistraw = @view get_member(ebg, "/common/edge_based_edge_list")[1:(n_ebe * sizeof(EdgeBasedEdge))]
    return reinterpret(reshape, EdgeBasedEdge, reshape(ebelistraw, sizeof(EdgeBasedEdge), :))
end
    