#include <osrm/json_container.hpp>

// Functions for working with JSON

extern "C" bool json_obj_member_is_null (osrm::json::Object * obj, char * key) {
    return std::holds_alternative<osrm::json::Null>(obj->values.at(key));
}

extern "C" osrm::json::Array * json_obj_get_arr (osrm::json::Object * obj, char * key) {
    return & std::get<osrm::json::Array>(obj->values.at(key));
}

extern "C" osrm::json::Object * json_obj_get_obj (osrm::json::Object * obj, char * key) {
    return & std::get<osrm::json::Object>(obj -> values.at(key));
}

extern "C" double json_obj_get_number (osrm::json::Object * obj, char * key) {
    return std::get<osrm::json::Number>(obj->values.at(key)).value;
}

extern "C" const char * json_obj_get_string (osrm::json::Object * obj, char * key) {
    // TODO should this have a &?
    return std::get<osrm::json::String>(obj->values.at(key)).value.c_str();
}

// extern "C" bool json_arr_get_bool (osrm::json::Array * obj, size_t key) {
//     BoolVisitor v;
//     apply_visitor(v, obj->values.at(key));
//     return v.get_value();
// }

extern "C" bool json_arr_member_is_null (osrm::json::Array * obj, size_t key) {
    return std::holds_alternative<osrm::json::Null>(obj -> values.at(key));
}

extern "C" osrm::json::Array * json_arr_get_arr (osrm::json::Array * obj, size_t key) {
    return & std::get<osrm::json::Array>(obj -> values.at(key));
}

extern "C" osrm::json::Object * json_arr_get_obj (osrm::json::Array * obj, size_t key) {
    return & std::get<osrm::json::Object>(obj -> values.at(key));
}

extern "C" double json_arr_get_number (osrm::json::Array * obj, size_t key) {
    return std::get<osrm::json::Number>(obj -> values.at(key)).value;
}

extern "C" const char * json_arr_get_string (osrm::json::Array * obj, size_t key) {
    return std::get<osrm::json::String>(obj -> values.at(key)).value.c_str();
}

extern "C" int json_arr_length (osrm::json::Array * arr) {
    return arr->values.size();
}

extern "C" bool json_obj_has_key (osrm::json::Object * obj, char * key) {
    return obj->values.contains(key);
}