# Test that hints work correctly.
# Hints allow controlling location snapping. Routes and distance matrices with different
# sets of points may result in differences in snapping (adding an arbitrary point may cause
# other points to snap differently - this is intentional, see https://github.com/Project-OSRM/osrm-backend/issues/6629)
# One place this comes up is when running a distance matrix and then trying to find individual routes for a subset of
# the locations; the routes may snap differently and thus give different travel times/distances.

@testitem "Hints" begin
    import Artifacts: @artifact_str
    import Geodesy: LatLon

    # this is using the example in https://github.com/Project-OSRM/osrm-backend/issues/6629
    mktempdir() do tempdir
        # copy the st paul south OSM file
        cp(joinpath(artifact"st_paul_south_osm", "st_paul_south.osm.pbf"), joinpath(tempdir, "st_paul_south.osm.pbf"))
        netpath = OSRM.build(joinpath(tempdir, "st_paul_south.osm.pbf"), OSRM.Profiles.Foot, OSRM.Algorithm.MultiLevelDijkstra)

        # Load up OSRM
        osrm = OSRMInstance(netpath, OSRM.Algorithm.MultiLevelDijkstra)

        # route without hints. This will snap to the service roads, which are in a disconnected component,
        # rather than to the larger network
        no_hints = route(osrm, LatLon(44.741725, -93.045528), LatLon(44.736798, -93.040551))
        @test length(no_hints) == 1
        @test no_hints[1].duration_seconds ≈ 291.2
        @test no_hints[1].distance_meters ≈ 404.3

        # distance matrix, with confounder point that causes snapping to larger component
        dmat = distance_matrix(osrm, [LatLon(44.741725, -93.045528)], [LatLon(44.736798, -93.040551), LatLon(44.796958, -93.082025)])
        @test dmat.duration_seconds[1, 1] ≈ 12925.3
        @test dmat.distance_meters[1, 1] ≈ 16525.5

        # route with hints
        hints = route(osrm, LatLon(44.741725, -93.045528), LatLon(44.736798, -93.040551);
            origin_hint=dmat.origin_waypoints[1].hint, destination_hint=dmat.destination_waypoints[1].hint)
        @test length(hints) == 1

        # This is the most critical aspect of this test. While overall durations may change due to changes in OSRM versions,
        # the test confirms that using the hints causes snapping to work the same way for both distance matrices and routing.
        @test no_hints[1].duration_seconds != hints[1].duration_seconds
        @test hints[1].duration_seconds == dmat.duration_seconds[1, 1]
        @test no_hints[1].distance_meters != hints[1].distance_meters
        @test hints[1].distance_meters == dmat.distance_meters[1, 1]
    end
end