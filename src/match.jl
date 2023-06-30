struct Tracepoint
    lat::Float64
    lon::Float64
    snap_distance_meters::Float64
    route_index::Int64
    within_route_index::Int64
    alternatives_count::Int64
end

struct MapMatchResult
    routes::Vector{Route}
    tracepoints::Vector{Union{Nothing, Tracepoint}}
end

function parse_match(resultptr, res)
    @info "running callback"

    resultvec::Vector{MapMatchResult} = unsafe_pointer_to_objref(res)
    result = resultvec[1]

    routeptr = json_obj_has_key(resultptr, "matchings")
    # for i in 0:(json_arr_length(routeptr) - 1)
    #     push!(result.routes, parse_route(json_arr_get_obj(routeptr, i)))
    # end
    
    return zero(Int32)
end

function parse_tracepoint(tptr)
    nothing
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
    result = MapMatchResult(Route[], Tracepoint[])

    parse_match_c = @cfunction(parse_match, Cint, (Ptr{Any}, Ptr{Any}))

    radius_vector = if isnothing(std_error_meters)
         Float64[]
    elseif std_error_meters isa Real
        fill(std_error_meters, length(points))
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