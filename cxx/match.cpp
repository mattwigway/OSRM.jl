/*
 * Contains code to call the OSRM map matcher.
 */

#include <cstdlib>
#include <osrm/json_container.hpp>
#include <osrm/coordinate.hpp>
#include <osrm/match_parameters.hpp>
#include <osrm/osrm.hpp>
#include <osrm/status.hpp>
#include <iostream>

using namespace std;

/*
 * Call the OSRM map matcher. "timestamps" should be in seconds since Unix epoch.
 * Returns -1 if OSRM error, 0 otherwise.
 */
extern "C" int osrm_match (struct osrm::OSRM * osrminst, double * lats, double * lons, unsigned * timestamps, size_t n_points,
    int (*callback)(osrm::json::Object*, void*), void * result_array) {
    
    using namespace osrm;

    MatchParameters params;

    for (size_t i = 0; i < n_points; i++) {
        params.coordinates.push_back({util::FloatLongitude{lons[i]}, util::FloatLatitude{lats[i]}});
        params.timestamps.push_back(timestamps[i]);
    }

    params.geometries = RouteParameters::GeometriesType::GeoJSON;

    engine::api::ResultT result = json::Object();    

    Status stat = osrminst->Match(params, result);

    auto &json_result = result.get<json::Object>();

    if (stat == Status::Ok) {
        return callback(&json_result, result_array);
    } else {
        auto code = json_result.values.at("code").get<osrm::json::String>().value.c_str();
        cout << "OSRM error: " << code << endl;
        return -1;
    }
}