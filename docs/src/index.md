# OSRM.jl

OSRM.jl is a Julia wrapper around the [OSRM](https://github.com/Project-OSRM/osrm-backend) C++ routing engine for high performance routing on OpenStreetMap data. 

Installing OSRM is a little more complicated than most Julia packages, because it requires building the OSRM backend and a C++ shim from source. See [Installation](@ref) for more details.

Before you can use OSRM for routing, you need to [Build an OSRM network](@ref) and [Load your network in Julia](@ref).
