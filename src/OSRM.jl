module OSRM

import Geodesy: LatLon
import ArchGDAL

const osrmjl = "libosrmjl"

include("instance.jl")
include("matrix.jl")
include("route.jl")

export start_osrm, stop_osrm!, route, distance_matrix

end
