"""
    build(osmpbf, profile, algorithm)

Build an OSRM network from the OSM data in `osmpbf`, the profile file specified in
`profile`, and the algorithm specified.

The `osmpbf` should contain the OpenStreetMap data you wish to use, in
[PBF format](https://wiki.openstreetmap.org/wiki/PBF_Format). [Protomaps](https://app.protomaps.com/)
is a good tool to extract OSM data.

The profile is a Lua profile that specifies how to weight and process the OSM data
(e.g. for bicycles, for cars, for bicycles avoiding busy streets, etc.). It can either
be a path to a custom Lua file, or one of the members of OSRM.Profiles.

The algorithm is OSRM.Algorithm.ContractionHierarchies or
OSRM.Algorithm.MultiLevelDijkstra. Contraction hierarchies performs better for computing distance
matrices, and multi-level Dijkstra is preferred for other applications (though both will work with all
OSRM functions).

The resulting network will be stored in the same directory and with the same name as the
OSM file (with different extension). There are a number of files that constitute a network,
all ending with .osrm.something.

Returns the path to the built OSRM network.
"""
function build(osmpbf, profile, algorithm::Algorithm.T)
    extensionre = r"(\.osm)?\.pbf?$"

    if isnothing(match(extensionre, osmpbf))
        error("OSM file should end in .pbf or .osm.pbf, got $osmpbf")
    end

    netname = replace(osmpbf, extensionre=>".osrm")

    # osrm-extract is the same for all
    @info "Extracting $osmpbf to network $(netname).* using profile $profile"
    run(`$(osrm_extract()) $osmpbf -p $profile`)

    if algorithm == Algorithm.CH
        @info "Contracting $netname"
        run(`$(osrm_contract()) $(netname)`)
    elseif algorithm == Algorithm.MLD
        run(`$(osrm_partition()) $(netname)`)
        run(`$(osrm_customize()) $(netname)`)
    end

    return netname
end