@testitem "Map matching" begin
    import Artifacts: @artifact_str
    import Geodesy: LatLon
    include("geojson.jl")
    using ReferenceTests: @test_reference

    # this is using the example in https://github.com/Project-OSRM/osrm-backend/issues/6629
    mktempdir() do tempdir
        # copy the st paul south OSM file
        cp(joinpath(artifact"st_paul_south_osm", "st_paul_south.osm.pbf"), joinpath(tempdir, "st_paul_south.osm.pbf"))

        # find foot.lua
        # TODO this is probably fragile
        osrm_path = readchomp(`which osrm-extract`)
        car_lua_path = joinpath(dirname(dirname(osrm_path)), "share", "osrm", "profiles", "car.lua")

        isfile(car_lua_path) || error("locating car.lua failed")

        # build the graph (MLD)
        osmpath = joinpath(tempdir, "st_paul_south.osm.pbf")
        netpath = joinpath(tempdir, "st_paul_south.osm.pbf")
        run(`osrm-extract -p $car_lua_path $osmpath`, wait=true)
        run(`osrm-partition $netpath`, wait=true)
        run(`osrm-customize $netpath`, wait=true)

        # Load up OSRM
        osrm = OSRMInstance(netpath, "mld")

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
