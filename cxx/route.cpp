#include <osrm/table_parameters.hpp>
#include <osrm/route_parameters.hpp>
#include <osrm/engine_config.hpp>
#include <osrm/coordinate.hpp>
#include <osrm/status.hpp>
#include <osrm/json_container.hpp>
#include <osrm/osrm.hpp>
#include <math.h>

#include <cstdlib>
#include <iostream>

/**
 * General parameters for OSRM service queries.
 *
 * Holds member attributes:
 *  - coordinates: for specifying location(s) to services
 *  - hints: hint for the service to derive the position(s) in the road network more efficiently, optional per coordinate.
 *      Multiple segment hints can be provided for a coordinate.
 *  - radiuses: limits the search for segments in the road network to given radius(es) in meter, optional per coordinate.
 *  - bearings: limits the search for segments in the road network to given bearing(s) in degree towards true north in
 *      clockwise direction, optional per coordinate
 *  - approaches: force the phantom node to start towards the node with the road country side or its opposite.
 *  - exclude: restrict certain road classes from routing, List of classes to avoid, order does not matter.
 *  // - format: output format of the response, either JSON or FLATBUFFERS
 *  - generate_hints: whether to generate hints for each route coordinate
 *  - skip_waypoints:
 *  - snapping: type of snapping to use for the given coordinates
 *  - steps: return route step for each route leg
 *  - alternatives: tries to find alternative routes
 *  - number_of_alternatives: max number of alternative routes to return
 *  // - geometries: route geometry encoded in Polyline, Polyline6 or GeoJSON
 *  - overview: adds overview geometry either Full, Simplified (according to highest zoom level) or False (not at all)
 *  - continue_straight: enable or disable continue_straight (disabled by default)
 *  - waypoints: list of indices that should be treated as waypoints
 *
 * \see OSRM, Coordinate, Hint, Bearing, RouteParameters, TableParameters,
 *      NearestParameters, TripParameters, MatchParameters and TileParameters
 */

extern "C" int osrm_route(
    struct osrm::OSRM *osrm,
    size_t n_coordinates, // number of coordinates
    double *lat_coordinates,
    double *lon_coordinates,
    char **hints,          // same length as coordinates with optional values, "" is nothing
    double *radiuses,      // same length as coordinates with optional values, -1.0 is nothing
    short *value_bearings, // same length as coordinates with optional values, 361 is nothing
    short *range_bearings, // same length as coordinates with optional values, 181 is nothing
    int *approaches,       // same length as coordinates with optional values, -1 is nothing
    size_t n_exclude,      // number of exclude
    char **exclude,
    // we only allow JSON
    // size_t format, // 0 is JSON, 1 is FLATBUFFERS
    bool generate_hints,
    bool skip_waypoints,
    size_t snapping, // 0 is Default, 1 is Any
    bool steps,
    bool alternatives,
    size_t number_of_alternatives,
    bool annotations,
    size_t annotations_type, // 0 is None, 1 is Duration, 2 is Nodes, 4 is Distance, 8 is Weight, 16 is Datasources, 32 is Speed, 63 is All
    // we only allow GeoJSON
    // size_t geometries,       // 0 is Polyline, 1 is Polyline6, 2 is GeoJSON
    size_t overview, // 0 is Simplified, 1 is Full, 2 is False
    bool continue_straight,
    size_t n_waypoints,
    size_t *waypoints,
    int (*callback)(osrm::json::Object *, void *),
    void *result_array)
{
    using namespace osrm;

    // add the input parameters into RouteParameters
    // see osrm api definition for more details:
    // https://github.com/Project-OSRM/osrm-backend/blob/master/include/engine/api/base_parameters.hpp
    // https://github.com/Project-OSRM/osrm-backend/blob/master/include/engine/api/route_parameters.hpp
    RouteParameters params;
    for (size_t i = 0; i < n_coordinates; i++)
    {
        params.coordinates.push_back({util::FloatLongitude{lon_coordinates[i]}, util::FloatLatitude{lat_coordinates[i]}});

        if (hints[i] != "")
        {
            params.hints.push_back(osrm::engine::Hint::FromBase64(std::string(hints[i])));
        }
        else
        {
            params.hints.emplace_back();
        }

        if (radiuses[i] != -1.0)
        {
            params.radiuses.push_back(radiuses[i]);
        }
        else
        {
            params.radiuses.emplace_back();
        }

        if (value_bearings[i] != 361 && range_bearings[i] != 181)
        {
            params.bearings.push_back(osrm::engine::Bearing{value_bearings[i], range_bearings[i]});
        }
        else
        {
            params.bearings.emplace_back();
        }
    }
    for (size_t i = 0; i < n_exclude; i++)
    {
        params.exclude.push_back(exclude[i]);
    }
    // we only support JSON
    // params.format = static_cast<RouteParameters::OutputFormatType>(format);
    params.format = RouteParameters::OutputFormatType::JSON;
    params.generate_hints = generate_hints;
    params.skip_waypoints = skip_waypoints;
    params.snapping = static_cast<RouteParameters::SnappingType>(snapping);
    params.steps = steps;
    params.alternatives = alternatives;
    params.number_of_alternatives = number_of_alternatives;
    params.annotations = annotations;
    params.annotations_type = static_cast<RouteParameters::AnnotationsType>(annotations_type);
    // we only support GeoJSON
    // params.geometries = static_cast<RouteParameters::GeometriesType>(geometries);
    params.geometries = RouteParameters::GeometriesType::GeoJSON;
    params.overview = static_cast<RouteParameters::OverviewType>(overview);
    params.continue_straight = continue_straight;
    for (size_t i = 0; i < n_waypoints; i++)
    {
        params.waypoints.push_back(waypoints[i]);
    }

    // call the OSRM Route function
    engine::api::ResultT result = json::Object();

    const auto status = osrm->Route(params, result);

    if (status != Status::Ok)
        return -1;

    auto result_body = std::get<json::Object>(result);

    return callback(&result_body, result_array);
}
