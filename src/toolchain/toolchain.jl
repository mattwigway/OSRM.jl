# Code to access OSRM Toolchain files
# Format documentation: https://github.com/Telenav/open-source-spec/blob/master/osrm/doc/osrm-toolchain-files/README.md

module Toolchain

import Tar
import Mmap: mmap
import Logging: @info, @warn
import Geodesy: LatLon

include("mmaptar.jl")
include("bits.jl")
include("edge_based_node.jl")
include("edge_based_edge.jl")
include("node_based_edge_annotation.jl")
include("node_based_node.jl")
include("geometry.jl")
include("names.jl")
include("properties.jl")

struct OSRMToolchain
    edge_based_edges::AbstractVector{EdgeBasedEdge}
    edge_based_nodes::AbstractVector{EdgeBasedNode}
    edge_based_node_weights::AbstractVector{Weight}
    edge_based_node_durations::AbstractVector{Float32}
    edge_based_node_distances::AbstractVector{Float32}
    edge_based_node_annotations::AbstractVector{NodeBasedEdgeAnnotation}
    geometry::GeometryVector
    node_coordinates::AbstractVector{Coordinate}
    class_names::AbstractVector{String}
    # TODO the indices here don't match OSRM, or even off by one, because OSRM uses a flat array of names, so each name takes five slots
    # in the vector. We put them into a struct so are off by a factor of 5 (plus off by one to boot). Correct way to get a name
    # currently is names[name_id ÷ 5 + 1]
    names::AbstractVector{Name}
end

function OSRMToolchain(osrm)
    if ltoh(0x01) != 0x01
        @warn "OSRM toolchains only tested on little-endian systems, but running on a big-endian system"
    end

    weights = read_edge_based_node_weights(osrm)

    OSRMToolchain(
        load_edge_based_edges(osrm),
        load_edge_based_nodes(osrm),
        weights.weights,
        weights.durations,
        weights.distances,
        load_edge_based_node_annotations(osrm),
        load_geometry(osrm),
        load_node_coordinates(osrm),
        read_class_names(osrm),
        read_names(osrm)
    )
end

include("geometry_helper.jl")

end