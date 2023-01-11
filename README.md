# OSRM

This package provides a Julia interface to the efficient [Open Source Routing Machine (OSRM)](https://project-osrm.org) library to provide street routing using OpenStreetMap data.


## Installation

OSRM.jl and uses Julia's ccall functionality to call OSRM. Since OSRM is written in C++, and ccall only works with C functions, OSRM.jl includes a very small C++ shim around OSRM with `extern "C"` functions to initialize, route, and shut down an OSRM routing engine. The code for this is in the `cxx` folder of this repository. This shim is built as a shared library libosrmjl.so (libosrmjl.dylib on Mac, libosrmjl.dll on Windowns) which contains a shim around OSRM, and is built from the code in the `cxx` folder. Before you can build `libosrmjl`, you need to have [osrm-backend](https://github.com/Project-OSRM/osrm-backend) installed, with libosrm.so, libosrm.dylib, or libosrm.dll somewhere in your library path. This may require building osrm-backend from source. The Docker images will be of no use here.

Once osrm-backend is installed, in the cxx/build directory, run `cmake ..` then `cmake --build ..` If all goes well, there will be no errors, and this will create a file called libosrm.so or libosrm.dylib in the build directory. In order for TransitRouter.jl to find this library, it either needs to be moved into a system-wide library directory (e.g. /usr/local/lib) or Julia needs to be run with the path to the cxx/build in the environment variable LD_LIBRARY_PATH (e.g. "LD_LIBRARY_PATH=~/OSRM.jl/cxx/build/:$LD_LIBRARY_PATH"" julia ...).

An OSRM network will need to be built in order to use street routing. An OSRM network should be prepared using the normal tools from the OSRM project; currently there is no functionality within OSRM.jl for network building. Instructions for preparing a .osrm file from an OpenStreetMap extract of the area in question are found in OSRM's quick start documentation. The documentation describes using OSRM in Docker, but using OSRM within TransitRouter.jl requires OSRM be installed locally. The instructions translate well if you just remove `docker run -t -v "${PWD}:/data" osrm/osrm-backend` from the start of commands, and pass paths on the local file system.

For instance, to build an OSRM network for Southern California using multi-level Dijkstra for use in walk routing, you would run:

    osrm-extract -p /usr/local/share/osrm/profiles/foot.lua socal-latest.osm.pbf
    osrm-partition socal-latest.osrm
    osrm-customize socal-latest.osrm
