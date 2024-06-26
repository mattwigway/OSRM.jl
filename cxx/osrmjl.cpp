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

// set up wrapper functions so we can use ccall in julia to call out to cpp osrm
// see https://isocpp.org/wiki/faq/mixing-c-and-cpp#overview-mixing-langs

/**
 * Start up an OSRM Engine, and return an opaque pointer to it (on the Julia side, it can be a Ptr{Any}).
 * Pass in the path to a built OSRM graph, and the string for whether you are using multi-level Dijkstra (MLD)
 * or contraction hierarchies (CH)
 */
extern "C" struct osrm::OSRM * init_osrm (char * osrm_path, char * algorithm) {
    using namespace osrm;
    EngineConfig config;
    config.storage_config = {osrm_path};
    config.use_shared_memory = false;  // TODO this may have something to do with thread safety

    if (strcmp(algorithm, "ch") == 0) config.algorithm = EngineConfig::Algorithm::CH;
    else if (strcmp(algorithm, "mld") == 0) config.algorithm = EngineConfig::Algorithm::MLD;
    else throw std::runtime_error("algorithm must be 'ch' or 'mld'");

    try {
        osrm::OSRM * engn = new osrm::OSRM(config);
        return engn;
    } catch (osrm::util::exception e) {
        std::cerr << e.what() << "\n";
        return nullptr;
    }
}

/**
 * Compute a distance matrix from origins to destinations, using the specified OSRM instance (an opaque Ptr{Any} returned
 * by init_osrm on the Julia side). Write results into the durations and distances arrays.
 */
extern "C" int distance_matrix(struct osrm::OSRM * osrm, size_t n_origins, double * origin_lats, double * origin_lons,
    size_t n_destinations, double * destination_lats, double * destination_lons, 
    int (*callback)(osrm::json::Object*, void*), void * result_obj) {
    using namespace osrm;

    // Create table parameters. concatenate origins and destinations into coordinates, set origin/destination references.
    TableParameters params;
    for (size_t i = 0; i < n_origins; i++) {
        params.sources.push_back(i);
        params.coordinates.push_back({util::FloatLongitude{origin_lons[i]}, util::FloatLatitude{origin_lats[i]}});
    }

    for (size_t i = 0; i < n_destinations; i++) {
        params.destinations.push_back(i + n_origins);
        params.coordinates.push_back({util::FloatLongitude{destination_lons[i]}, util::FloatLatitude{destination_lats[i]}});
    }

    params.annotations = TableParameters::AnnotationsType::All;

    engine::api::ResultT result = json::Object();    

    Status stat = osrm->Table(params, result);

    if (stat != Status::Ok) return -1;

    auto &json_result = std::get<json::Object>(result);

    return callback(&json_result, result_obj);
}

/**
 * Compute an OSRM point-to-point route.
 */
extern "C" int osrm_route (struct osrm::OSRM * osrm, double origin_lat, double origin_lon, double destination_lat, double destination_lon,
        char * origin_hint, char * destination_hint,
        int (*callback)(osrm::json::Object*, void*), void * result_array) {
    using namespace osrm;

    RouteParameters params;
    params.coordinates.push_back({util::FloatLongitude{origin_lon}, util::FloatLatitude{origin_lat}});
    params.coordinates.push_back({util::FloatLongitude{destination_lon}, util::FloatLatitude{destination_lat}});
    params.geometries = RouteParameters::GeometriesType::GeoJSON;
    params.overview = RouteParameters::OverviewType::Full;
    params.annotations = true;
    params.steps = true;

    // error will be raised on the Julia side if they're not both NULL or non-NULL
    if (origin_hint != NULL && destination_hint != NULL) {
        params.hints.push_back(osrm::engine::Hint::FromBase64(std::string(origin_hint)));
        params.hints.push_back(osrm::engine::Hint::FromBase64(std::string(destination_hint)));
    }

    engine::api::ResultT result = json::Object();

    const auto status = osrm->Route(params, result);

    if (status != Status::Ok) return -1;

    auto result_body = std::get<json::Object>(result);

    return callback(&result_body, result_array);
}

/**
 * Shut down an OSRM engine when it is no longer needed.
 */
extern "C" void stop_osrm (struct osrm::OSRM * engn) {
    delete engn;
}