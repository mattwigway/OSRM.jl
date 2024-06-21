# Build an OSRM network

An OSRM network will need to be built in order to use street routing. An OSRM network should be prepared using the normal tools from the OSRM project; currently there is no functionality within OSRM.jl for network building. Instructions for preparing a .osrm file from an OpenStreetMap extract of the area in question are found in OSRM's quick start documentation. The documentation describes using OSRM in Docker, but using OSRM within TransitRouter.jl requires OSRM be installed locally. The instructions translate well if you just remove `docker run -t -v "${PWD}:/data" osrm/osrm-backend` from the start of commands, and pass paths on the local file system.

For instance, to build an OSRM network for Southern California using multi-level Dijkstra for use in walk routing, you would run:

    osrm-extract -p /usr/local/share/osrm/profiles/foot.lua socal-latest.osm.pbf
    osrm-partition socal-latest.osrm
    osrm-customize socal-latest.osrm

Multi-level Dijkstra is generally recommended for routing, while contraction hierarchies is more efficient for computing distance matrices.