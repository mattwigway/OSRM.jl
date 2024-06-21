# TODO unify with Waypoint, they're the same basically
struct Tracepoint
    location::LatLon{Float64}
    snap_distance_meters::Float64
    matchings_index::Int64
    within_matching_index::Int64
    alternatives_count::Int64
end

struct MapMatchResult
    matchings::Vector{Route}
    confidence::Vector{Float64}
    tracepoints::Vector{Union{Nothing, Tracepoint}}
end

function parse_match(resultptr, res)
    resultvec::Vector{MapMatchResult} = unsafe_pointer_to_objref(res)
    result = resultvec[1]

    routesptr = json_obj_get_arr(resultptr, "matchings")
    for i in json_arr_indices(routesptr)
        routeptr = json_arr_get_obj(routesptr, i)
        push!(result.matchings, parse_route(routeptr))
        push!(result.confidence, json_obj_get_number(routeptr, "confidence"))
    end

    pointsptr = json_obj_get_arr(resultptr, "tracepoints")
    for i in json_arr_indices(pointsptr)
        push!(result.tracepoints, parse_tracepoint(pointsptr, i))
    end
    
    return zero(Int32)
end

function parse_tracepoint(pointsptr, index)
    if json_arr_member_is_null(pointsptr, index)
        nothing
    else
        tp = json_arr_get_obj(pointsptr, index)
        coords = json_obj_get_arr(tp, "location")
        Tracepoint(
            LatLon(json_arr_get_number(coords, 1), json_arr_get_number(coords, 0)),
            json_obj_get_number(tp, "distance"),
            convert(Int64, json_obj_get_number(tp, "matchings_index")),
            convert(Int64, json_obj_get_number(tp, "waypoint_index")),
            convert(Int64, json_obj_get_number(tp, "alternatives_count"))
        )
    end
end

"""
```
mapmatch(
        osrm::OSRMInstance,
        points;
        timestamps,
        std_error_meters::Union{Nothing, <:Real, <:AbstractVector{<:Real}}=nothing,
        tidy=false,
        annotations=false,
        steps=false,
        split_gaps=true
        )
```

Perform map matching using OSRM.

The only required arguments are an OSRMInstance and geometry to match (represented as a vector of `LatLon`s). You can additionally
provide timestamps for each of the points (as a vector of Julia `DateTime` objects), and standard errors for the GPS points. The
standard error can either be a scalar or a vector of the same length as the number of points. OSRM will (as of this writing) search
for matching roads up to `3 * std_error_meters` meters from each point. Higher numbers make the algorithm significantly slower.

- `tidy` allows OSRM to modify the input to clean it up
- `annotations` includes annotations in the returned routes. The annotations include the OSM node IDs the route uses.
- `steps` includes turn-by-turn directions
- `split_gaps` instructs OSRM to split the trace when there is a large gap between timestamps.

The result is a MapMatchResult object, which has several attributes.

- `matchings` contains a vector of Routes (like those returned by `route()`) of the matched routes. The most interesting attributes will likely be `geometry`
    (the snapped geometry) and `annotation.nodes` (the OSM nodes passed through)
- `confidence` is a value between 0 and 1 with OSRM's confidence in each route
- `tracepoints` contains information on where each point was snapped to. Note that points that could not be snapped will have the value `nothing`.
    They are skipped in map matching, and if they occur at the start or end of the trace (or if there is only one snapped point before/after them),
    the trace will be truncated.

More details on map matching in OSRM are availble in the [OSRM API docs](http://project-osrm.org/docs/v5.24.0/api/#match-service).
"""
function mapmatch(
        osrm::OSRMInstance,
        points::AbstractVector{LatLon{Float64}};
        timestamps::Union{Nothing, <:AbstractVector{DateTime}}=nothing,
        # should be radii, but we'll match OSRM
        std_error_meters::Union{Nothing, <:Real, <:AbstractVector{<:Real}}=nothing,
        tidy=false,
        annotations=false,
        steps=false,
        split_gaps=true
        )
    result = MapMatchResult(Route[], Float64[], Tracepoint[])

    parse_match_c = @cfunction(parse_match, Cint, (Ptr{Any}, Ptr{Any}))

    radius_vector = if isnothing(std_error_meters)
         Float64[]
    elseif std_error_meters isa Real
        fill(convert(Float64, std_error_meters), length(points))
    else
        length(points) == length(std_error_meters) || error("Length of points and timestamps must match!")
        convert.(Float64, std_error_meters)
    end

    timestamp_vector = if isnothing(timestamps)
        DateTime[]
    else
        length(points) == length(timestamps) || error("Length of points and timestamps must match!")
        timestamps
    end

    status = @ccall libosrmjl.osrm_match(
        osrm._engine::Ptr{Any},
        [x.lat for x in points]::Ptr{Float64},
        [x.lon for x in points]::Ptr{Float64},
        length(points)::Csize_t,
        round.(UInt32, datetime2unix.(timestamp_vector))::Ptr{UInt32},
        length(timestamp_vector)::Csize_t,
        radius_vector::Ptr{Float64},
        length(radius_vector)::Csize_t,
        tidy::Bool,
        annotations::Bool,
        steps::Bool,
        split_gaps::Bool,
        parse_match_c::Ptr{Any},
        # enclosing vector becasue we can only pass mutable objs through ccall
        pointer_from_objref([result])::Ptr{Any}
        )::Cint

    status == 0 || error("OSRM error")

    return result
end