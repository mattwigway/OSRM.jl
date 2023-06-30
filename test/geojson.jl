import JSON: json

geometry_to_geojson(x) = json(
    Dict(
        "type"=>"FeatureCollection",
        "features"=>[
            Dict(
                "type"=>"Feature",
                "properties"=>Dict(),
                "geometry"=>Dict(
                    "type"=>"LineString",
                    "coordinates"=>[[ll.lon, ll.lat] for ll in x]
                )
            )
        ]
    )
)