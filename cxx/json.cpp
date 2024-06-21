#include <osrm/json_container.hpp>

// Functions for working with JSON

extern "C" bool json_obj_member_is_null (osrm::json::Object * obj, char * key) {
    return obj->values.at(key).match(
        [] (osrm::json::Null) { return true; },
        // https://github.com/mapbox/variant/issues/140
        [] (auto) { return false; }
    );
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

// extern "C" bool json_arr_get_bool (osrm::json::Array * obj, size_t key) {
//     BoolVisitor v;
//     apply_visitor(v, obj->values.at(key));
//     return v.get_value();
// }

extern "C" bool json_arr_member_is_null (osrm::json::Array * obj, size_t key) {
    return obj->values.at(key).match(
        [] (osrm::json::Null) { return true; },
        // https://github.com/mapbox/variant/issues/140
        [] (auto) { return false; }
    );
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

extern "C" bool json_obj_has_key (osrm::json::Object * obj, char * key) {
    // don't use contains, mapbox variant compile fails with C++20
    // https://www.techiedelight.com/determine-if-a-key-exists-in-a-map-in-cpp/
    return obj->values.count(key) == 1;
}