function read_class_names(osrm)
    profile_properties_tar = read_tar_mmap(osrm * ".properties", strict=false)
    profile_properties = get_member(profile_properties_tar, "/common/properties")
    # NB this format may be fragile, there is a note at https://github.com/Telenav/open-source-spec/blob/master/osrm/doc/osrm-toolchain-files/map.osrm.properties.md
    offset = 277
    result = Vector{String}()
    for _ in 1:8
        str = @view profile_properties[offset:offset + 255]
        endstr = findfirst(str .== 0x0)
        classname = String(str[begin:(endstr - 1)])
        if !isempty(classname)
            push!(result, classname)
            offset += 256
        else
            break
        end
    end

    return result
end