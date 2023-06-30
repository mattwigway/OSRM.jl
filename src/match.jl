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

    status = @ccall osrmjl.osrm_match(
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