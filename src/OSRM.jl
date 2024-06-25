module OSRM

import Geodesy: LatLon
import ArchGDAL
import EnumX: @enumx
import Dates: DateTime, datetime2unix
import OSRM_jll: osrm_extract, osrm_contract, osrm_partition, osrm_customize
import OSRM_jll
import osrmjl_jll: libosrmjl
import osrmjl_jll
import Libdl: dlopen

function __init__()
    # when building the JLLs, we set dont_dlopen=true, because Yggdrasil runs Julia 1.7,
    # which can't dlopen libraries built with the GCC 12 runtime required by OSRM. However,
    # a side effect of this is that the JLLs themselves don't autoload the libraries, so we have
    # to load them manually. Even though we don't use any functions from libosrm.so directly,
    # we have to dlopen it first so that it is available when we load libosrmjl.so - because
    # libosrm.so is not on the loadpath for libosrmjl.so. H/T Mosé Giordano.
    dlopen(OSRM_jll.libosrm_path)
    dlopen(osrmjl_jll.libosrmjl_path)
end

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
