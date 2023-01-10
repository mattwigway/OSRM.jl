mutable struct OSRMInstance
    _engine::Ptr{Any}
    file_path::String
    algorithm::String
    running::Bool
end

# Start OSRM, with the file path to an already built OSRM graph, and an algorithm
# specification which is mld for multi-level Dijkstra, and ch for contraction hierarchies.
function start_osrm(file_path::String, algorithm::String)::OSRMInstance
    algorithm = lowercase(algorithm)

    if (algorithm != "mld" && algorithm != "ch")
        error("Algorithm must be 'mld' for Multi-Level Dijkstra, or 'ch' for Contraction Hierarchies.")
    end

    ptr = @ccall osrmjl.init_osrm(file_path::Cstring, algorithm::Cstring)::Ptr{Any}
    return OSRMInstance(ptr, file_path, algorithm, true)
end

function stop_osrm!(osrm::OSRMInstance)
    if osrm.running
        @ccall osrmjl.stop_osrm(osrm._engine::Ptr{Any})::Cvoid
        osrm.running = false
    else
        @warn "stop_osrm! called on already stopped OSRM instance"
    end
end