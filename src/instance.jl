@enumx Algorithm ContractionHierarchies MultiLevelDijkstra
get_abbr(a::Algorithm.T) = if a == Algorithm.ContractionHierarchies
    "ch"
elseif a == Algorithm.MultiLevelDijkstra
    "mld"
else
    error("Unrecognized algorithm")
end

mutable struct OSRMInstance
    _engine::Ptr{Any}
    file_path::String
    algorithm::OSRM.Algorithm.T

    # Start OSRM, with the file path to an already built OSRM graph, and an algorithm
    # specification which is mld for multi-level Dijkstra, and ch for contraction hierarchies.
    function OSRMInstance(file_path::String, algorithm::OSRM.Algorithm.T)
        # Check for file existence

        ptr = @ccall libosrmjl.init_osrm(file_path::Cstring, repr(algorithm)::Cstring)::Ptr{Any}

        if ptr == C_NULL
            # TODO would be better to get the actual error here
            error("Error initializing OSRM (see stderr).")
        end

        result = new(ptr, file_path, algorithm)

        finalizer(result) do osrm
            @ccall libosrmjl.stop_osrm(osrm._engine::Ptr{Any})::Cvoid
        end
    end
end