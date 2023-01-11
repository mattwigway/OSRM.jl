mutable struct OSRMInstance
    _engine::Ptr{Any}
    file_path::String
    algorithm::String

    # Start OSRM, with the file path to an already built OSRM graph, and an algorithm
    # specification which is mld for multi-level Dijkstra, and ch for contraction hierarchies.
    function OSRMInstance(file_path::String, algorithm::String)
        algorithm = lowercase(algorithm)

        if (algorithm != "mld" && algorithm != "ch")
            error("Algorithm must be 'mld' for Multi-Level Dijkstra, or 'ch' for Contraction Hierarchies.")
        end

        ptr = @ccall osrmjl.init_osrm(file_path::Cstring, algorithm::Cstring)::Ptr{Any}
        result = new(ptr, file_path, algorithm)

        finalizer(result) do osrm
            @ccall osrmjl.stop_osrm(osrm._engine::Ptr{Any})::Cvoid
        end
    end
end