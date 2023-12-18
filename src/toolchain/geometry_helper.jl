function get_geometry(t::OSRMToolchain, n::EdgeBasedNode)
    coords = map(t.geometry[n.geometry_id]) do internal_node_id
        coord = t.node_coordinates[internal_node_id + 1]
        LatLon(coord.lat, coord.lon)
    end

    return if n.forward
        coords
    else
        reverse(coords)
    end
end

function get_node_ids(t::OSRMToolchain, n::EdgeBasedNode)
    nodes = map(t.geometry[n.geometry_id]) do internal_node_id
        t.node_ids[internal_node_id + 1]
    end

    return if n.forward
        nodes
    else
        reverse(nodes)
    end
end