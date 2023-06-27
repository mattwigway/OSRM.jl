@enumx DrivingSide Left Right

struct RouteAnnotation
    distance_meters::Union{Vector{Float64}, Nothing}
    duration_seconds::Union{Vector{Float64}, Nothing}
    weight::Union{Vector{Float64}, Nothing}
    nodes::Union{Vector{Int64}, Nothing}
    speed::Union{Vector{Float64}, Nothing}
    # leaving off datasources and metadata for now
end

struct StepManeuver
    location::LatLon{Float64}
    bearing_before::Float64
    bearing_after::Float64
    type::String
    modifier::Union{String, Nothing}
    exit::Union{Int64, Nothing}
end

struct RouteIntersection
    location::LatLon{Float64}
    bearings::Vector{Float64}
    classes::Union{Vector{String}, Nothing}
    in_index::Union{Int32, Nothing}
    out_index::Union{Int32, Nothing}
    # no lanes for now
end

struct RouteStep
    distance_meters::Float64
    duration_seconds::Float64
    geometry::Union{Nothing, Vector{LatLon{Float64}}}
    weight::Float64
    name::String
    ref::Union{String, Nothing}
    pronunciation::Union{String, Nothing}
    mode::String
    maneuver::StepManeuver
    intersections::Vector{RouteIntersection}
    rotary_name::Union{Nothing, String}
    rotary_pronunciation::Union{Nothing, String}
    driving_side::DrivingSide.T
end

struct RouteLeg
    distance_meters::Float64
    duration_seconds::Float64
    weight::Float64
    summary::String
    steps::Vector{RouteStep}
    annotation::RouteAnnotation
end

struct Route
    distance_meters::Float64
    duration_seconds::Float64
    geometry::Union{Nothing, Vector{LatLon{Float64}}}
    weight::Float64
    weight_name::String
    legs::Vector{RouteLeg}
end

function parse_routes(result, resultptr)
    try
        resultarray = unsafe_pointer_to_objref(resultptr)::Vector{Route}
        routes = json_obj_get_arr(result, "routes")
        n_routes = json_arr_length(routes)
        for rtidx_1based in 1:n_routes
            rtidx_0based = rtidx_1based - 1
            rtptr = json_arr_get_obj(routes, rtidx_0based)
            push!(resultarray, parse_route(rtptr))
        end
        return zero(Int32)
    catch e
        println(e)
        println(stacktrace(catch_backtrace()))
        return convert(Int32, -2)
    end
end

# parse the Json from OSRM into Julia Route object
function parse_route(rtptr)
    distance_meters = json_obj_get_number(rtptr, "distance")
    duration_seconds = json_obj_get_number(rtptr, "duration")
    weight = json_obj_get_number(rtptr, "weight")

    weight_name = json_obj_get_string(rtptr, "weight_name")
    geom_ptr = json_obj_get_obj(rtptr, "geometry")
    geom = parse_linestring(geom_ptr)

    legs_ptr = json_obj_get_arr(rtptr, "legs")
    n_legs = json_arr_length(legs_ptr)

    legs = map(0:(n_legs - 1)) do legidx
        leg_ptr = json_arr_get_obj(legs_ptr, legidx)
        parse_leg(leg_ptr)
    end

    return Route(distance_meters, duration_seconds, geom, weight, weight_name, legs)
end

function parse_leg(leg_ptr)
    distance_meters = json_obj_get_number(leg_ptr, "distance")
    duration_seconds = json_obj_get_number(leg_ptr, "duration")
    weight = json_obj_get_number(leg_ptr, "weight")
    summary = json_obj_get_string(leg_ptr, "summary")
    steps_ptr = json_obj_get_arr(leg_ptr, "steps")
    ann_ptr = json_obj_get_obj(leg_ptr, "annotation")

    steps = map(json_arr_indices(steps_ptr)) do idx
        step_ptr = json_arr_get_obj(steps_ptr, idx)
        parse_step(step_ptr)
    end

    annotation = parse_annotation(ann_ptr)

    return RouteLeg(distance_meters, duration_seconds, weight, summary, steps, annotation)
end

function parse_annotation(ann_ptr)
    # all annotations are optional and can be disabled, in which case, json_obj_get_arr will return
    # a RouteAnnotation with all fields containing `nothing`
    distance_ptr = json_obj_get_arr(ann_ptr, "distance")
    distance_meters = !isnothing(distance_ptr) ?
        map(i -> json_arr_get_number(distance_ptr, i), json_arr_indices(distance_ptr)) :
        nothing
    
    duration_ptr = json_obj_get_arr(ann_ptr, "duration")
    duration_seconds = !isnothing(duration_ptr) ?
        map(i -> json_arr_get_number(duration_ptr, i), json_arr_indices(duration_ptr)) :
        nothing

    weight_ptr = json_obj_get_arr(ann_ptr, "weight")
    weight = !isnothing(weight_ptr) ?
        map(i -> json_arr_get_number(weight_ptr, i), json_arr_indices(weight_ptr)) :
        nothing

    nodes_ptr = json_obj_get_arr(ann_ptr, "nodes")
    nodes = !isnothing(nodes_ptr) ?
        # All JSON numbers stored as floating point
        map(i -> convert(Int64, json_arr_get_number(nodes_ptr, i)), json_arr_indices(nodes_ptr)) :
        nothing

    speed_ptr = json_obj_get_arr(ann_ptr, "speed")
    speed = !isnothing(speed_ptr) ?
        map(i -> json_arr_get_number(speed_ptr, i), json_arr_indices(speed_ptr)) :
        nothing

    return RouteAnnotation(distance_meters, duration_seconds, weight, nodes, speed)
end

function parse_step(step_ptr)
    distance_meters = json_obj_get_number(step_ptr, "distance")
    duration_seconds = json_obj_get_number(step_ptr, "duration")
    geometry = parse_linestring(json_obj_get_obj(step_ptr, "geometry"))
    weight = json_obj_get_number(step_ptr, "weight")
    name = json_obj_get_string(step_ptr, "name")
    ref = json_obj_get_string(step_ptr, "ref")
    pronunciation = json_obj_get_string(step_ptr, "pronunciation")
    mode = json_obj_get_string(step_ptr, "mode")
    maneuver = parse_maneuver(json_obj_get_obj(step_ptr, "maneuver"))
    rotary_name = json_obj_get_string(step_ptr, "rotary_name")
    rotary_pronunciation = json_obj_get_string(step_ptr, "rotary_pronunciation")

    intersections_ptr = json_obj_get_arr(step_ptr, "intersections")
    intersections = map(json_arr_indices(intersections_ptr)) do i
        intersection_ptr = json_arr_get_obj(intersections_ptr, i)
        parse_intersection(intersection_ptr)
    end

    driving_side_str = json_obj_get_string(step_ptr, "driving_side")
    driving_side = if driving_side_str == "left"
        DrivingSide.Left
    elseif driving_side_str == "right"
        DrivingSide.Right
    end

    return RouteStep(distance_meters, duration_seconds, geometry, weight, name,
        ref, pronunciation, mode, maneuver, intersections, rotary_name, rotary_pronunciation, driving_side)
end

function parse_intersection(int_ptr)
    llptr = json_obj_get_arr(int_ptr, "location")
    lon = json_arr_get_number(llptr, 0)
    lat = json_arr_get_number(llptr, 1)
    loc = LatLon(lat, lon)
    
    bearings_ptr = json_obj_get_arr(int_ptr, "bearings")
    bearings = map(i -> json_arr_get_number(bearings_ptr, i), json_arr_indices(bearings_ptr))

    classes_ptr = json_obj_get_arr(int_ptr, "classes")
    classes = !isnothing(classes_ptr) ? map(i -> json_arr_get_string(classes_ptr, i), json_arr_indices(classes_ptr)) : nothing

    # TODO json_arr_get_bool not working yet
    # entry_ptr = json_obj_get_arr(int_ptr, "entry")
    # entry = map(i -> json_arr_get_bool(entry_ptr, i), json_arr_indices(entry_ptr))

    in_index = convert(Union{Int32, Nothing}, json_obj_get_number(int_ptr, "in"))
    out_index = convert(Union{Int32, Nothing}, json_obj_get_number(int_ptr, "out"))

    return RouteIntersection(loc, bearings, classes, in_index, out_index)
end

function parse_maneuver(man_ptr)
    llptr = json_obj_get_arr(man_ptr, "location")
    lon = json_arr_get_number(llptr, 0)
    lat = json_arr_get_number(llptr, 1)
    loc = LatLon(lat, lon)

    bearing_before = json_obj_get_number(man_ptr, "bearing_before")
    bearing_after = json_obj_get_number(man_ptr, "bearing_after")

    type = json_obj_get_string(man_ptr, "type")

    modifier = json_obj_get_string(man_ptr, "modifier")

    exit = json_obj_get_number(man_ptr, "exit")
    exitnum = !isnothing(exit) ? convert(Int64, exit) : nothing

    return StepManeuver(loc, bearing_before, bearing_after, type, modifier, exitnum)
end

function parse_linestring(geom_ptr)
    geom_type = json_obj_get_string(geom_ptr, "type")
    geom_type == "LineString" || error("Expected LineString geometry, found $geom_type")

    linestring = LatLon{Float64}[]
    coords_ptr = json_obj_get_arr(geom_ptr, "coordinates")
    n_coords = json_arr_length(coords_ptr)

    for coordidx in 0:(n_coords - 1)
        coord_ptr = json_arr_get_arr(coords_ptr, coordidx)
        n = json_arr_length(coord_ptr)
        n == 2 || error("wrong number of coordinates")
        lng = json_arr_get_number(coord_ptr, 0)
        lat = json_arr_get_number(coord_ptr, 1)
        push!(linestring, LatLon{Float64}(lat, lng))
    end

    return linestring
end

function route(osrm::OSRMInstance, origin::LatLon{T}, destination::LatLon{T}; origin_hint=nothing, destination_hint=nothing) where T <: Real
    result = Route[]

    isnothing(origin_hint) == isnothing(destination_hint) || error("Origin and destination hints must either both be present, or both not be present!")

    parse_routes_c = @cfunction(parse_routes, Cint, (Ptr{Any}, Ptr{Any}))

    status = @ccall osrmjl.osrm_route(
        osrm._engine::Ptr{Any},
        convert(Float64, origin.lat)::Float64,
        convert(Float64, origin.lon)::Float64,
        convert(Float64, destination.lat)::Float64,
        convert(Float64, destination.lon)::Float64,
        (isnothing(origin_hint) ? C_NULL : origin_hint)::Cstring,
        (isnothing(destination_hint) ? C_NULL : destination_hint)::Cstring,
        parse_routes_c::Ptr{Any},
        (pointer_from_objref(result))::Ptr{Any}
    )::Cint

    if status != 0
        # routing failed
        return Route[]
    end

    return result
end