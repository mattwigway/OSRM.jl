"""
This contains the default profiles shipped with OSRM, accessible as:
    
    OSRM.Profiles.Car
    OSRM.Profiles.Bicycle
    OSRM.Profiles.Foot
"""
module Profiles
    import OSRM_jll

    const Car = OSRM_jll.car
    const Bicycle = OSRM_jll.bicycle
    const Foot = OSRM_jll.foot
end