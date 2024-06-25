@testitem "Map matching" begin
    import Artifacts: @artifact_str
    import Geodesy: LatLon
    include("geojson.jl")
    using ReferenceTests: @test_reference

    # this is using the example in https://github.com/Project-OSRM/osrm-backend/issues/6629
    mktempdir() do tempdir
        # copy the st paul south OSM file
        cp(joinpath(artifact"st_paul_south_osm", "st_paul_south.osm.pbf"), joinpath(tempdir, "st_paul_south.osm.pbf"))
        netpath = OSRM.build(joinpath(tempdir, "st_paul_south.osm.pbf"), OSRM.Profiles.Car, OSRM.Algorithm.MultiLevelDijkstra)

        # Load up OSRM
        osrm = OSRMInstance(netpath, OSRM.Algorithm.MultiLevelDijkstra)

        # First a very simple map matching south of St Paul
        path = [
            LatLon(44.746790, -93.160026),
            LatLon(44.748831, -93.164088),
            LatLon(44.750089, -93.164758),
            LatLon(44.7504864, -93.15724)
        ]

        res = mapmatch(osrm, path; annotations=true, split_gaps=false)

        @test !any(isnothing.(res.tracepoints))
        @test length(res.matchings) == 1
        @test_reference "snapshots/simple.geojson" geometry_to_geojson(res.matchings[1].geometry)
    end
end
