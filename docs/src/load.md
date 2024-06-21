# Load your network in Julia

Now that you've built an OSRM network, you can load it into Julia very easily. If you built a multi-level Dijkstra network, you would do the following. If you built a contraction hierarchies network you would replace `"mld"` with `"ch"`

```{julia}
using OSRM

osrm = OSRMInstance("path/to/network.osrm", "mld")
```

Now that you have an OSRM instance, you can do several things with it (see links in sidebar).