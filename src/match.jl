struct MapMatchResult
    routes::Vector{Route}
end

function parse_match(resultptr, res)
    result::Vector{Route} = unsafe_pointer_to_objref(res)

    routeptr = json_obj_get_arr(resultptr, "matchings")
    for i in 0:(json_arr_length(routeptr) - 1)
        push!(result, parse_route(json_arr_get_obj(routeptr, i)))
    end
    
    return zero(Int32)
end

function mapmatch(osrm::OSRMInstance, points::Vector{LatLon{Float64}}, timestamps::Vector{DateTime})
    result = Vector{Route}()

    length(points) == length(timestamps) || error("Length of points and timestamps must match!")

    parse_match_c = @cfunction(parse_match, Cint, (Ptr{Any}, Ptr{Any}))

    status = @ccall osrmjl.osrm_match(
        osrm._engine::Ptr{Any},
        [x.lat for x in points]::Ptr{Float64},
        [x.lon for x in points]::Ptr{Float64},
        round.(UInt32, datetime2unix.(timestamps))::Ptr{UInt32},
        length(points)::Csize_t,
        parse_match_c::Ptr{Any},
        pointer_from_objref(result)::Ptr{Any}
        )::Cint

    status == 0 || error("OSRM error")

    return MapMatchResult(result)
end