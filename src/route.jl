struct Route
    distance_meters::Float64
    duration_seconds::Float64
    geometry::Union{Nothing, ArchGDAL.IGeometry{ArchGDAL.wkbLineString}}
    weight::Float64
    weight_name::String
end

function parse_routes(result, resultptr)
    try
        resultarray = unsafe_pointer_to_objref(resultptr)::Vector{Route}
        routes = @ccall osrmjl.json_obj_get_arr(result::Ptr{Any}, "routes"::Cstring)::Ptr{Any}
        n_routes = @ccall osrmjl.json_arr_length(routes::Ptr{Any})::Cint
        for rtidx_1based in 1:n_routes
            rtidx_0based = rtidx_1based - 1
            rtptr = @ccall osrmjl.json_arr_get_obj(routes::Ptr{Any}, rtidx_0based::Csize_t)::Ptr{Any}
            push!(resultarray, parse_route(rtptr))
        end
        return zero(Int32)
    catch e
        println(e)
        return convert(Int32, -2)
    end
end

function route(osrm::OSRMInstance, origin::LatLon{T}, destination::LatLon{T}) where T <: Real
    result = Route[]

    parse_routes_c = @cfunction(parse_routes, Cint, (Ptr{Any}, Ptr{Any}))

    status = @ccall osrmjl.osrm_route(
        osrm._engine::Ptr{Any},
        convert(Float64, origin.lat)::Float64,
        convert(Float64, origin.lon)::Float64,
        convert(Float64, destination.lat)::Float64,
        convert(Float64, destination.lon)::Float64,
        parse_routes_c::Ptr{Any},
        (pointer_from_objref(result))::Ptr{Any}
    )::Cint

    if status != 0
        error("Routing failed: OSRMJL status $status")
    end

    return result
end

function parse_route(rtptr::Ptr{Any})
    distance_meters = @ccall osrmjl.json_obj_get_number(rtptr::Ptr{Any}, "distance"::Cstring)::Cdouble
    duration_seconds = @ccall osrmjl.json_obj_get_number(rtptr::Ptr{Any}, "duration"::Cstring)::Cdouble
    weight = @ccall osrmjl.json_obj_get_number(rtptr::Ptr{Any}, "weight"::Cstring)::Cdouble

    weight_name = @ccall osrmjl.json_obj_get_string(rtptr::Ptr{Any}, "weight_name"::Cstring)::Cstring
    geom_ptr = @ccall osrmjl.json_obj_get_obj(rtptr::Ptr{Any}, "geometry"::Cstring)::Ptr{Any}
    geom = parse_linestring(geom_ptr)

    # unsafe_ because if ptr is not a string will be an issue. But ok to free the string on C side afterwars,
    # unsafe_string creates a protective copy
    return Route(distance_meters, duration_seconds, geom, weight, unsafe_string(weight_name))
end

function parse_linestring(geom_ptr)
    geom_type = @ccall osrmjl.json_obj_get_string(geom_ptr::Ptr{Any}, "type"::Cstring)::Cstring
    unsafe_string(geom_type) == "LineString" || error("Expected LineString geometry, found $geom_type")

    linestring = ArchGDAL.createlinestring()
    coords_ptr = @ccall osrmjl.json_obj_get_arr(geom_ptr::Ptr{Any}, "coordinates"::Cstring)::Ptr{Any}
    n_coords = @ccall osrmjl.json_arr_length(coords_ptr::Ptr{Any})::Csize_t

    for coordidx in 0:(n_coords - 1)
        coord_ptr = @ccall osrmjl.json_arr_get_arr(coords_ptr::Ptr{Any}, coordidx::Csize_t)::Ptr{Any}
        n = @ccall osrmjl.json_arr_length(coord_ptr::Ptr{Any})::Csize_t
        n == 2 || error("wrong number of coordinates")
        lng = @ccall osrmjl.json_arr_get_number(coord_ptr::Ptr{Any}, 0::Csize_t)::Cdouble
        lat = @ccall osrmjl.json_arr_get_number(coord_ptr::Ptr{Any}, 1::Csize_t)::Cdouble
        ArchGDAL.addpoint!(linestring, lng, lat)
    end

    return linestring
end