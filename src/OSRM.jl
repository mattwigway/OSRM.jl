module OSRM

import Geodesy: LatLon
import ArchGDAL
import EnumX: @enumx
import Dates: DateTime, datetime2unix
import OSRM_jll: osrm_extract, osrm_contract, osrm_partition, osrm_customize
import osrmjl_jll: libosrmjl

include("json.jl")
include("instance.jl")
include("matrix.jl")
include("route.jl")
include("toolchain/toolchain.jl")
include("match.jl")
include("profiles.jl")
include("build.jl")

export OSRMInstance, route, distance_matrix, mapmatch

end
