function get_geometry(t::OSRMToolchain, n::EdgeBasedNode)
    map(t.geometry[n.geometry_id]) do internal_node_id
        coord = t.node_coordinates[internal_node_id + 1]
        LatLon(coord.lat, coord.lon)
    end
end