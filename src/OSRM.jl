module OSRM

import Geodesy: LatLon
import ArchGDAL
import EnumX: @enumx

const osrmjl = "libosrmjl"

include("json.jl")
include("instance.jl")
include("matrix.jl")
include("route.jl")

export OSRMInstance, route, distance_matrix

end
