module OSRM

import Geodesy: LatLon
import ArchGDAL
import EnumX: @enumx
import Dates: DateTime, datetime2unix

const osrmjl = "libosrmjl"

include("json.jl")
include("instance.jl")
include("matrix.jl")
include("route.jl")
include("toolchain/toolchain.jl")
include("match.jl")

export OSRMInstance, route, distance_matrix, mapmatch

end
