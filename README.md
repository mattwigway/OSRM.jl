# OSRM

This package provides a Julia interface to the efficient [Open Source Routing Machine (OSRM)](https://project-osrm.org) library to provide street routing using OpenStreetMap data. It supports one-to-one routing, many-to-many routing, and map-matching. It runs on macOS and Linux; for Windows, I recommend the [Windows Subsystem for Linux](https://learn.microsoft.com/en-us/windows/wsl/install).

## Installation

As of version 0.3.0, OSRM.jl and all of its dependencies are available through the Julia package manager, although they are not yet in the General registry. They are available in [my personal registry](https://github.com/mattwigway/PublicJuliaRepository), which you can add by running 

`]registry add https://github.com/mattwigway/PublicJuliaRegistry.git`

at the Julia REPL. You can then run

`]add OSRM`

to install OSRM.jl. If you get many errors that packages were not found, it is possible my registry replaced the General registry, instead of adding to it; you can rectify this by running

`]registry add General`

OSRM.jl does not currently work on Windows due to compatibility issues between OSRM and Windows. It does work in the [Windows Subsystem for Linux](https://learn.microsoft.com/en-us/windows/wsl/install).

## Building a network

Before you can use OSRM.jl, you need to build an OSRM network. The `OSRM.build` function will build a network. It is used like this:

```julia
OSRM.build("path/to/file.osm.pbf", OSRM.Profiles.Car, OSRM.Algorithm.MultiLevelDijktra)
```

and of course will only work after running `using OSRM` or `import OSRM`.

This will build a network from the `osm.pbf` file specified. The network will be stored in a bunch of files in the same directory and with the same name as the `osm.pbf` file, but with different extensions starting with `.osrm` (for this reason, you cannot build multiple networks from the same `osm.pbf` file; if you want to build a car and bicycle network, for example, you will need to make two copies of your `osm.pbf` file).

The second argument is the "profile." An [OSRM profile](https://github.com/Project-OSRM/osrm-backend/blob/master/docs/profiles.md) is a Lua script that OSRM uses to assign weights to OSM ways and nodes. OSRM ships with three default profiles: Car, Bicycle, and Foot, which are accessible as `OSRM.Profiles.Car`, etc. You can also create your own profile and refer to its filename here. In fact, the members of OSRM.Profiles are just strings pointing to where the default profiles are installed on your system.

The third argument is the algorithm for routing, which can be with `OSRM.Algorithm.MultiLevelDijkstra` or `OSRM.Algorithm.ContractionHierarchies`. Both algorithms support all OSRM functionality, but for performance, contraction hierarichies is preferred when computing distance matrices (using the `distance_matrix` function), and multi-level Dijkstra is preferred for other uses (including building up distance matrices from multiple `route` calls if you need to extract more information than `distance_matrix` provides).

You only need to build the network once, it does not need to be rebuilt to be used again (although it is good practice to rebuild it when switching to a different machine or OSRM version).

You can also build a network from the command line if you like, following the [instructions from OSRM](https://github.com/Project-OSRM/osrm-backend/), but for compatibility you will want to use the same OSRM binaries you are using from Julia, not ones from Docker. If you installed OSRM using the steps above to install through the Julia package manager, the correct OSRM binaries will be hidden somewhere in your `.julia/artifacts` folder, so I recommend against this approach.

## Loading a network

Once you've built a network, you need to load it. This is done with the `OSRMInstance` type:

```julia
osrm = OSRMInstance("path/to/network.osrm", OSRM.Algorithm.MultiLevelDijkstra)
```

The path is the path to `osm.pbf` file you used, with the extension switched to `.osrm`. Note that no file with the extension `.osrm` exists, but it is a prefix for many other files (e.g. `.osrm.ebg`). The algorithm must match the one you used when building the network.

## Routing

For point-to-point routing, you can use the `route` function like so:

```julia
result = route(osrm, LatLon(37.363, -122.123), LatLon(37.421, -122.098))
```

`LatLon` comes from the Geodesy.jl package which will need to be loaded first. This returns a Vector of routes between the first and second point (generally only one, or zero if no route was found). The each route contains the following fields:

- `distance_meters`: The length of the route, in meters
- `duration_seconds`: The travel time of the route, in seconds
- `geometry`: The geometry of the route, as a Vector of `LatLon` objects
- `weight`: The weight of the route (units are profile-dependent)
- `weight_name`: The name of the weight from the profile (e.g. distance, routability)
- `legs`: A Vector of the individual legs of the route. Since OSRM.jl currently does not support multi-leg routes (i.e. between more than two points), there should always be one leg.

Each leg object contains the following:

- `distance_meters`: The distance of the leg, in meters
- `duration_seconds`: The duration, in seconds
- `weight`: The total weight
- `summary`: 
- `steps`: 
- `annotation`: An annotation object, which contains more information about the OSM nodes the leg uses

The main attribute of interest in the annotation object is the `nodes` member, which is a vector of OSM node IDs that the leg used.

## Multithreading

OSRM routing and mapmatching functions are thread-safe. Note that, for distance matrices, dividing up a large distance matrix call into smaller calls may affect routing, as snapping the origins and destinations to the network is dependent on the other origins and destinations in the function call.