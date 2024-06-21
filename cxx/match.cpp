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
extern "C" int osrm_match (struct osrm::OSRM * osrminst, double * lats, double * lons, size_t n_points,
    unsigned * timestamps, size_t n_timestamps,
    double * radii, size_t n_radii,
    bool tidy, bool annotations, bool steps, bool split_gaps,
    int (*callback)(osrm::json::Object*, void*), void * result_array) {
    
    using namespace osrm;

    MatchParameters params;

    for (size_t i = 0; i < n_points; i++) {
        params.coordinates.push_back({util::FloatLongitude{lons[i]}, util::FloatLatitude{lats[i]}});
    }

    for (size_t i = 0; i < n_timestamps; i++) {
        params.timestamps.push_back(timestamps[i]);
    }

    for (size_t i = 0; i < n_radii; i++) {
        params.radiuses.push_back(radii[i]);
    }

    params.tidy = tidy;

    if (annotations) {
        params.annotations = true;
        params.annotations_type = RouteParameters::AnnotationsType::All;
    } else {
        params.annotations = false;
    }


    params.steps = steps;
    if (split_gaps) {
        params.gaps = MatchParameters::GapsType::Split;
    } else {
        params.gaps = MatchParameters::GapsType::Ignore;
    }

    params.overview = RouteParameters::OverviewType::Full;

    params.geometries = RouteParameters::GeometriesType::GeoJSON;

    engine::api::ResultT result = json::Object();    

    Status stat = osrminst->Match(params, result);

    if (stat == Status::Ok) {
        auto &json_result = std::get<json::Object>(result);
        return callback(&json_result, result_array);
    } else {
        auto code = std::get<osrm::json::String>(std::get<json::Object>(result).values.at("code")).value.c_str();
        cout << "OSRM error: " << code << endl;
        return -1;
    }
}