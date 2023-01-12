#include <osrm/table_parameters.hpp>
#include <osrm/route_parameters.hpp>
#include <osrm/engine_config.hpp>
#include <osrm/coordinate.hpp>
#include <osrm/status.hpp>
#include <osrm/json_container.hpp>
#include <osrm/osrm.hpp>
#include <math.h>

#include <cstdlib>

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

    osrm::OSRM * engn = new osrm::OSRM(config);

    return engn;
}

/**
 * Compute a distance matrix from origins to destinations, using the specified OSRM instance (an opaque Ptr{Any} returned
 * by init_osrm on the Julia side). Write results into the durations and distances arrays.
 */
extern "C" int distance_matrix(struct osrm::OSRM * osrm, size_t n_origins, double * origin_lats, double * origin_lons,
    size_t n_destinations, double * destination_lats, double * destination_lons, double * durations, double * distances) {
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

    auto &json_result = result.get<json::Object>();

    std::vector<json::Value> jdurations = json_result.values["durations"].get<json::Array>().values;
    std::vector<json::Value> jdistances = json_result.values["distances"].get<json::Array>().values;

    // copy it into the result array
    // jdurations, jdistances are multidimensional arrays

    for (size_t destination = 0; destination < n_destinations; destination++) {
        for (size_t origin = 0; origin < n_origins; origin++) {
            // julia arrays: col-major order
            const size_t off = destination * n_origins + origin;

            const auto duration = jdurations.at(origin).get<json::Array>().values.at(destination);
            if (duration.is<json::Null>()) durations[off] = NAN;
            else durations[off] = double(duration.get<json::Number>().value);

            const auto distance = jdistances.at(origin).get<json::Array>().values.at(destination);
            if (distance.is<json::Null>()) distances[off] = NAN;
            else distances[off] = double(distance.get<json::Number>().value);
        }
    }

    return 0;
}

/**
 * Compute an OSRM point-to-point route.
 */
extern "C" int osrm_route (struct osrm::OSRM * osrm, double origin_lat, double origin_lon, double destination_lat, double destination_lon,
        int (*callback)(osrm::json::Object*, void*), void * result_array) {
    using namespace osrm;

    RouteParameters params;
    params.coordinates.push_back({util::FloatLongitude{origin_lon}, util::FloatLatitude{origin_lat}});
    params.coordinates.push_back({util::FloatLongitude{destination_lon}, util::FloatLatitude{destination_lat}});
    params.geometries = RouteParameters::GeometriesType::GeoJSON;
    params.overview = RouteParameters::OverviewType::Full;

    engine::api::ResultT result = json::Object();

    const auto status = osrm->Route(params, result);

    if (status != Status::Ok) return -1;

    auto result_body = result.get<json::Object>();

    return callback(&result_body, result_array);
}

extern "C" osrm::json::Array * json_obj_get_arr (osrm::json::Object * obj, char * key) {
    return & (obj->values.at(key).get<osrm::json::Array>());
}

extern "C" osrm::json::Object * json_obj_get_obj (osrm::json::Object * obj, char * key) {
    return & (obj->values.at(key).get<osrm::json::Object>());
}

extern "C" double json_obj_get_number (osrm::json::Object * obj, char * key) {
    return (obj->values.at(key).get<osrm::json::Number>().value);
}

extern "C" const char * json_obj_get_string (osrm::json::Object * obj, char * key) {
    return (obj->values.at(key).get<osrm::json::String>().value.c_str());
}

extern "C" osrm::json::Array * json_arr_get_arr (osrm::json::Array * obj, size_t key) {
    return & (obj->values.at(key).get<osrm::json::Array>());
}

extern "C" osrm::json::Object * json_arr_get_obj (osrm::json::Array * obj, size_t key) {
    return & (obj->values.at(key).get<osrm::json::Object>());
}

extern "C" double json_arr_get_number (osrm::json::Array * obj, size_t key) {
    return (obj->values.at(key).get<osrm::json::Number>().value);
}

extern "C" const char * json_arr_get_string (osrm::json::Array * obj, size_t key) {
    return (obj->values.at(key).get<osrm::json::String>().value.c_str());
}

extern "C" int json_arr_length (osrm::json::Array * arr) {
    return arr->values.size();
}

/**
 * Shut down an OSRM engine when it is no longer needed.
 */
extern "C" void stop_osrm (struct osrm::OSRM * engn) {
    delete engn;
}