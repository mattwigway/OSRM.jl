
function distance_matrix(osrm::OSRMInstance, origins::Vector{LatLon{T}}, destinations::Vector{LatLon{T}}) where T <: Real
    if !osrm.running
        error("OSRM is not running!")
    end

    n_origins::Csize_t = length(origins)
    n_destinations::Csize_t = length(destinations)
    origin_lats::Vector{Float64} = map(c -> convert(Float64, c.lat), origins)
    origin_lons::Vector{Float64} = map(c -> convert(Float64, c.lon), origins)
    destination_lats::Vector{Float64} = map(c -> convert(Float64, c.lat), destinations)
    destination_lons::Vector{Float64} = map(c -> convert(Float64, c.lon), destinations)

    durations::Array{Float64, 2} = fill(-1.0, (n_origins, n_destinations))::Array{Float64, 2}
    distances::Array{Float64, 2} = fill(-1.0, (n_origins, n_destinations))::Array{Float64, 2}

    stat = @ccall osrmjl.distance_matrix(
        osrm._engine::Ptr{Any},
        n_origins::Csize_t,
        origin_lats::Ptr{Float64},
        origin_lons::Ptr{Float64},
        n_destinations::Csize_t,
        destination_lats::Ptr{Float64},
        destination_lons::Ptr{Float64},
        durations::Ptr{Float64},
        distances::Ptr{Float64}
    )::Cint

    if (stat != 0)
        error("osrm failed, status $stat")
    end

    return (durations=durations, distances=distances)
end
