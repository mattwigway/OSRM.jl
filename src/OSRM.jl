module OSRM

import Geodesy: LatLon
import ArchGDAL

const osrmjl = "libosrmjl"

include("instance.jl")
include("matrix.jl")
include("route.jl")

export OSRMInstance, route, distance_matrix

end
