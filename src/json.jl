# wrapper functions for getting values from OSRM JSON::Result, to avoid repeating type statements
function json_obj_get_arr(ptr, key::AbstractString)
    if json_obj_has_key(ptr, key)
        @ccall osrmjl.json_obj_get_arr(ptr::Ptr{Any}, key::Cstring)::Ptr{Any}
    else
        nothing
    end
end

function json_obj_get_obj(ptr, key::AbstractString)
    if json_obj_has_key(ptr, key)
        @ccall osrmjl.json_obj_get_obj(ptr::Ptr{Any}, key::Cstring)::Ptr{Any}
    else
        nothing
    end
end

function json_obj_get_number(ptr, key::AbstractString)
    if json_obj_has_key(ptr, key)
        @ccall osrmjl.json_obj_get_number(ptr::Ptr{Any}, key::Cstring)::Cdouble
    else
        nothing
    end
end

# unsafe because it expects string data. it is ok if OSRM frees this string pointer later
function json_obj_get_string(ptr, key::AbstractString)
    if json_obj_has_key(ptr, key)
        unsafe_string(@ccall osrmjl.json_obj_get_string(ptr::Ptr{Any}, key::Cstring)::Cstring)
    else
        nothing
    end
end

function json_arr_get_arr(ptr, key::Integer) 
    if key < json_arr_length(ptr)
        @ccall osrmjl.json_arr_get_arr(ptr::Ptr{Any}, key::Csize_t)::Ptr{Any}
    else
        nothing
    end
end

function json_arr_get_obj(ptr, key::Integer) 
    if key < json_arr_length(ptr)
        @ccall osrmjl.json_arr_get_obj(ptr::Ptr{Any}, key::Csize_t)::Ptr{Any}
    else
        nothing
    end
end

function json_arr_get_number(ptr, key::Integer) 
    if key < json_arr_length(ptr)
        @ccall osrmjl.json_arr_get_number(ptr::Ptr{Any}, key::Csize_t)::Cdouble
    else
        nothing
    end
end

function json_arr_get_string(ptr, key::Integer) 
    if key < json_arr_length(ptr)
        unsafe_string(@ccall osrmjl.json_arr_get_string(ptr::Ptr{Any}, key::Csize_t)::Cstring)
    else
        nothing
    end
end

# function json_arr_get_bool(ptr, key::Integer) 
#     if key < json_arr_length(ptr)
#         @ccall osrmjl.json_arr_get_bool(ptr::Ptr{Any}, key::Csize_t)::Boolean
#     else
#         nothing
#     end
# end


json_arr_length(ptr) = @ccall osrmjl.json_arr_length(ptr::Ptr{Any})::Csize_t
json_arr_indices(ptr) = 0:(json_arr_length(ptr) - 1)
json_obj_has_key(ptr, key::AbstractString) = @ccall osrmjl.json_obj_has_key(ptr::Ptr{Any}, key::Cstring)::Bool