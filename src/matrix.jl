struct Waypoint
    hint::String
    # TODO other waypoint attrs
end

mutable struct MatrixResult
    duration_seconds::Matrix{Float64}
    distance_meters::Matrix{Float64}
    origin_waypoints::Vector{Waypoint}
    destination_waypoints::Vector{Waypoint}
end

function parse_matrix(json::Ptr{Any}, resultptr::Ptr{Any})
    try
        result = unsafe_pointer_to_objref(resultptr)::MatrixResult
        durations = json_obj_get_arr(json, "durations")
        distances = json_obj_get_arr(json, "distances")
        
        for origin in json_arr_indices(durations) 
            origin_durations = json_arr_get_arr(durations, origin)
            origin_dists = json_arr_get_arr(distances, origin)
            for destination in json_arr_indices(origin_durations)
                result.duration_seconds[origin + 1, destination + 1] = json_arr_get_number(origin_durations, destination)
                result.distance_meters[origin + 1, destination + 1] = json_arr_get_number(origin_dists, destination)
            end
        end

        sources = json_obj_get_arr(json, "sources")
        for wayptidx in json_arr_indices(sources)
            jway = json_arr_get_obj(sources, wayptidx)
            waypoint = Waypoint(json_obj_get_string(jway, "hint"))
            push!(result.origin_waypoints, waypoint)
        end

        destinations = json_obj_get_arr(json, "destinations")
        for wayptidx in json_arr_indices(destinations)
            jway = json_arr_get_obj(destinations, wayptidx)
            waypoint = Waypoint(json_obj_get_string(jway, "hint"))
            push!(result.destination_waypoints, waypoint)
        end

        return convert(Cint, 0)
    catch e
        @error e stacktrace(catch_backtrace())
        return convert(Cint, -2)
    end
end

function distance_matrix(osrm::OSRMInstance, origins::Vector{LatLon{T}}, destinations::Vector{LatLon{T}}) where T <: Real
    n_origins::Csize_t = length(origins)
    n_destinations::Csize_t = length(destinations)
    origin_lats::Vector{Float64} = map(c -> convert(Float64, c.lat), origins)
    origin_lons::Vector{Float64} = map(c -> convert(Float64, c.lon), origins)
    destination_lats::Vector{Float64} = map(c -> convert(Float64, c.lat), destinations)
    destination_lons::Vector{Float64} = map(c -> convert(Float64, c.lon), destinations)

    result = MatrixResult(
        fill(-1.0, (n_origins, n_destinations))::Array{Float64, 2},
        fill(-1.0, (n_origins, n_destinations))::Array{Float64, 2},
        Waypoint[],
        Waypoint[]
    )

    parse_matrix_c = @cfunction(parse_matrix, Cint, (Ptr{Any}, Ptr{Any}))

    stat = @ccall osrmjl.distance_matrix(
        osrm._engine::Ptr{Any},
        n_origins::Csize_t,
        origin_lats::Ptr{Float64},
        origin_lons::Ptr{Float64},
        n_destinations::Csize_t,
        destination_lats::Ptr{Float64},
        destination_lons::Ptr{Float64},
        parse_matrix_c::Ptr{Any},
        (pointer_from_objref(result))::Ptr{Any}
    )::Cint

    if (stat != 0)
        error("osrm failed, status $stat")
    end

    return result
end
